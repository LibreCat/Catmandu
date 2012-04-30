package Catmandu::Store::Solr;

use Catmandu::Sane;
use Moo;
use WebService::Solr;

with 'Catmandu::Store';

has url => (is => 'ro', default => sub { 'http://localhost:8983/solr' });

has solr => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_solr',
);

sub _build_solr {
    WebService::Solr->new($_[0]->url, {autocommit => 0, default_params => {wt => 'json'}});
}

package Catmandu::Store::Solr::Bag;

use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(:is);
use Catmandu::Hits;
use CQL::Solr;

with 'Catmandu::Bag';
with 'Catmandu::Searchable';
with 'Catmandu::Buffer';

sub generator {
    my ($self) = @_;
    my $store = $self->store;
    my $name  = $self->name;
    my $limit = $self->buffer_size;
    my $query = qq/_bag:"$name"/;
    sub {
        state $start = 0;
        state $hits;
        unless ($hits && @$hits) {
            $hits = $store->solr->search($query, {start => $start, rows => $limit})->content->{response}{docs};
            $start += $limit;
        }
        my $hit = shift(@$hits) || return;
        delete $hit->{_bag};
        $hit;
    };
}

sub count {
    my ($self) = @_;
    my $name = $self->name;
    my $res  = $self->store->solr->search(qq/_bag:"$name"/, {rows => 0});
    $res->content->{response}{numFound};
}

sub get {
    my ($self, $id) = @_;
    my $name = $self->name;
    my $res  = $self->store->solr->search(qq/_bag:"$name" AND _id:"$id"/, {rows => 1});
    my $hit  = $res->content->{response}{docs}->[0] || return;
    delete $hit->{_bag};
    $hit;
}

sub add {
    my ($self, $data) = @_;

    my @fields = (WebService::Solr::Field->new(_bag => $self->name));

    for my $key (keys %$data) {
        my $val = $data->{$key};
        if (is_array_ref($val)) {
            is_value($_) && push @fields, WebService::Solr::Field->new($key => $_) foreach @$val;
        } elsif (is_value($val)) {
            push @fields, WebService::Solr::Field->new($key => $val);
        }
    }

    $self->buffer_add(WebService::Solr::Document->new(@fields));

    if ($self->buffer_is_full) {
        $self->commit;
    }
}

sub delete {
    my ($self, $id) = @_;
    my $name = $self->name;
    $self->store->solr->delete_by_query(qq/_bag:"$name" AND _id:"$id"/);
}

sub delete_all {
    my ($self) = @_;
    my $name = $self->name;
    $self->store->solr->delete_by_query(qq/_bag:"$name"/);
}

sub delete_by_query {
    my ($self, %args) = @_;
    my $name = $self->name;
    $self->store->solr->delete_by_query(qq/_bag:"$name" AND ($args{query})/);
}

sub commit { # TODO better error handling
    my ($self) = @_;
    my $solr = $self->store->solr;
    my $err;
    if ($self->buffer_used) {
        eval { $solr->add($self->buffer) } or push @{$err ||= []}, $@;
        $self->clear_buffer;
    }
    eval { $solr->commit } or push @{$err ||= []}, $@;
    !defined $err, $err;
}

sub search {
    my ($self, %args) = @_;

    my $query = delete $args{query};
    my $start = delete $args{start};
    my $limit = delete $args{limit};
    my $bag   = delete $args{reify};

    my $name = $self->name;

    if ($args{fq}) {
        $args{fq} = qq/_bag:"$name" AND ($args{fq})/;
    } else {
        $args{fq} = qq/_bag:"$name"/;
    }

    my $res = $self->store->solr->search($query, {%args, start => $start, rows => $limit});

    my $set = $res->content->{response}{docs};

    if ($bag) {
        $set = [map { $bag->get($_->{_id}) } @$set];
    } else {
        delete $_->{_bag} for @$set;
    }

    my $hits = Catmandu::Hits->new({
        limit => $limit,
        start => $start,
        total => $res->content->{response}{numFound},
        hits  => $set,
    });

    if ($res->facet_counts) {
        $hits->{facets} = $res->facet_counts;
    }

    $hits;
}

sub searcher {
    my ($self, %args) = @_;
    Catmandu::Store::Solr::Searcher->new(%args, bag => $self);
}

sub translate_sru_sortkeys {
    confess 'TODO';
}

sub translate_cql_query {
    CQL::Solr->parse($_[1]);
}

sub normalize_query {
    $_[1] || "*:*";
}

package Catmandu::Store::Solr::Searcher;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Iterable';

has bag   => (is => 'ro', required => 1);
has query => (is => 'ro', required => 1);
has start => (is => 'ro', required => 1);
has limit => (is => 'ro', required => 1);
has total => (is => 'ro');

sub generator {
    my ($self) = @_;
    my $store = $self->bag->store;
    my $name  = $self->bag->name;
    my $limit = $self->limit;
    my $query = $self->query;
    my $fq    = qq/_bag:"$name"/;
    sub {
        state $start = $self->start;
        state $total = $self->total;
        state $hits;
        if (defined $total) {
            return unless $total;
        }
        unless ($hits && @$hits) {
            if ($total && $limit > $total) {
                $limit = $total;
            }
            $hits = $store->solr->search($query, {start => $start, rows => $limit, fq => $fq})->content->{response}{docs};
            $start += $limit;
        }
        if ($total) {
            $total--;
        }
        my $hit = shift(@$hits) || return;
        delete $hit->{_bag};
        $hit;
    };
}

sub slice { # TODO constrain total
    my ($self, $start, $total) = @_;
    $start //= 0;
    $self->new(
        bag   => $self->bag,
        query => $self->query,
        start => $self->start + $start,
        total => $total,
    );
}

sub count {
    my ($self) = @_;
    my $name = $self->bag->name;
    my $res  = $self->bag->store->solr->search($self->query, {rows => 0, fq => qq/_bag:"$name"/});
    $res->content->{response}{numFound};
}

1;

=head1 NAME

Catmandu::Store::Solr - A Catmandu::Store plugin for Solr search engines

=head1 SYNOPSIS

    use Catmandu::Store::Solr;

    my $store = Catmandu::Store::Solr->new(url => 'http://localhost:8983/solr' );

    my $obj1 = $store->bag->add({ name => 'Patrick' });

    printf "obj1 stored as %s\n" , $obj1->{_id};

    # Force an id in the store
    my $obj2 = $store->bag->add({ _id => 'test123' , name => 'Nicolas' });

    # Commit all changes
    $store->bag->commit;

    my $obj3 = $store->bag->get('test123');

    $store->bag->delete('test123');

    $store->bag->delete_all;

    # All bags are iterators
    $store->bag->each(sub { ... });
    $store->bag->take(10)->each(sub { ... });

    # Some stores can be searched
    my $hits = $store->bag->search(query => 'name:Patrick');

=head1 DESCRIPTION

A Catmandu::Store::Solr is a Perl package that can index data into
a Solr engine. The database as a whole is called a 'store'.
Databases also have compartments (e.g. tables) called Catmandu::Bag-s.
The Catmandu::Store::Solr can be searched using Catmandu::Searchable methods.

=head1 SUPPORT

Solr schemas need to support '_id' and '_bag' record fields to be able to
store Catmandu items.

=head1 METHODS

=head2 new(url => $solr_url)

Create a new Catmandu::Store::Solr store. 

=head2 bag($name)

Create or retieve a bag with name $name. Returns a Catmandu::Bag.

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>

=cut
