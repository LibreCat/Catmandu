package Catmandu::Store::ElasticSearch;

use Catmandu::Sane;
use Moo;
use ElasticSearch;

with 'Catmandu::Store';

my $ELASTIC_SEARCH_ARGS = [qw(
    transport
    servers
    trace_calls
    timeout
    max_requests
    no_refresh
)];

has index_name     => (is => 'ro', required => 1);
has index_settings => (is => 'ro', lazy => 1, default => sub { +{} });
has index_mappings => (is => 'ro', lazy => 1, default => sub { +{} });

has elastic_search => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_elastic_search',
);

sub _build_elastic_search {
    my $self = $_[0];
    my $es = ElasticSearch->new(delete $self->{_args});
    unless ($es->index_exists(index => $self->index_name)) {
        $es->create_index(
            index => $self->index_name,
            settings => $self->index_settings,
            mappings => $self->index_mappings,
        );
    }
    $es->use_index($self->index_name);
    $es;
}

sub BUILD {
    my ($self, $args) = @_;
    $self->{_args} = {};
    for my $key (@$ELASTIC_SEARCH_ARGS) {
        $self->{_args}{$key} = $args->{$key} if exists $args->{$key};
    }
}

package Catmandu::Store::ElasticSearch::Bag;

use Catmandu::Sane;
use Moo;
use CQL::ElasticSearch;
use Catmandu::Hits;

with 'Catmandu::Bag';
with 'Catmandu::Searchable';
with 'Catmandu::Buffer';

sub generator {
    my ($self) = @_;
    my $limit = $self->buffer_size;
    sub {
        state $scroller = $self->store->elastic_search->scrolled_search({
            search_type => 'scan',
            query => {match_all => {}},
            type  => $self->name,
        });
        state @hits;
        @hits = $scroller->next($limit) unless @hits;
        (shift(@hits) || return)->{_source};
    };
}

sub count {
    my ($self) = @_;
    $self->store->elastic_search->count(type => $self->name)->{count};
}

sub get {
    my ($self, $id) = @_;
    my $res = $self->store->elastic_search->get(
        type => $self->name,
        ignore_missing => 1,
        id => $id,
    );
    return $res->{_source} if $res;
    return;
}

sub add {
    my ($self, $data) = @_;

    $self->buffer_add({
        type => $self->name,
        id   => $data->{_id},
        data => $data,
    });

    if ($self->buffer_is_full) {
        $self->commit;
    }
}

sub delete {
    my ($self, $id) = @_;
    $self->store->elastic_search->delete(
        type => $self->name,
        ignore_missing => 1,
        id => $id,
    );
}

sub delete_all {
    my ($self) = @_;
    $self->store->elastic_search->delete_by_query(
        query => {match_all => {}},
        type  => $self->name,
    );
}

sub delete_by_query {
    my ($self, %args) = @_;
    $self->store->elastic_search->delete_by_query(
        query => $args{query},
        type  => $self->name,
    );
}

sub commit { # TODO optimize
    my ($self) = @_;
    return 1 unless $self->buffer_used;
    my $res = $self->store->elastic_search->bulk_index($self->buffer)->{results};
    my $err;
    for my $r (@$res) {
        if (my $e = $r->{index}{error}) {
            push @{$err ||= []}, $e;
        }
    }
    $self->clear_buffer;
    return !defined $err, $err;
}

sub search {
    my ($self, %args) = @_;

    my $query = delete $args{query};
    my $start = delete $args{start};
    my $limit = delete $args{limit};
    my $bag   = delete $args{reify};

    my $res = $self->store->elastic_search->search({
        %args,
        query => $query,
        type  => $self->name,
        from  => $start,
        size  => $limit,
    });

    my $set = $res->{hits}{hits};

    my $hits = Catmandu::Hits->new({
        start => $start,
        limit => $limit,
        total => $res->{hits}{total},
    });

    if ($bag) {
        $hits->{hits} = [ map { $bag->get($_->{_id}) } @$set ];
    } else {
        $hits->{hits} = [ map { $_->{_source} } @$set ];
    }

    if ($args{facets}) {
        $hits->{facets} = $res->{facets};
    }

    if ($args{highlight}) {
        for my $hit (@$set) {
            if (my $hl = $hit->{highlight}) {
                $hits->{highlight}{$hit->{_id}} = $hl;
            }
        }
    }

    $hits;
}

sub searcher {
    my ($self, %args) = @_;
    Catmandu::Store::ElasticSearch::Searcher->new(%args, bag => $self);
}

sub translate_cql_query {
    CQL::ElasticSearch->parse($_[1]);
}

sub normalize_query {
    my ($self, $query) = @_;
    if (ref $query) {
        $query;
    } elsif ($query) {
        {query_string => {query => $query}};
    } else {
        {match_all => {}};
    }
}

package Catmandu::Store::ElasticSearch::Searcher;

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
    my $limit = $self->limit;
    sub {
        state $total = $self->total;
        if (defined $total) {
            return unless $total;
        }
        state $scroller = $self->bag->store->elastic_search->scrolled_search({
            search_type => 'scan',
            query => $self->query,
            type  => $self->bag->name,
            from  => $self->start,
        });
        state @hits;
        unless (@hits) {
            if ($total && $limit > $total) {
                $limit = $total;
            }
            @hits = $scroller->next($limit);
        }
        if ($total) {
            $total--;
        }
        (shift(@hits) || return)->{_source};
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
    $self->bag->store->elastic_search->count(
        query => $self->query,
        type  => $self->bag->name,
    )->{count};
}

1;
