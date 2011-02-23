package Catmandu::Index::Solr;

use Moose;
use Hash::Flatten qw(:all);
use WebService::Solr;
use WebService::Solr::Field;
use WebService::Solr::Document;

with 'Catmandu::Index';

has url => (is => 'ro', isa => 'Str', default => 'http://localhost:8983/solr');

has maxdoc => (is => 'ro', isa => 'Int', default => 100);

has _indexer => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_indexer',
    predicate => '_has_indexer',
    clearer => '_clear_indexer',
);

has _stack => (
    traits => ['Array'],
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
    handles => {
        _push_stack  => 'push' ,
        _count_stack => 'count' ,
    }
);

sub _build_indexer {
    my $self = shift;
    WebService::Solr->new($self->url, { autocommit => 0 , default_params => { wt => 'json' }});
}

sub save {
    my ($self,$obj) = @_;
    my $id_field = $self->id_field;

    $obj->{$id_field} or confess "Missing $id_field";

    my @fields = ();

    foreach my $key (keys %$obj) {
        my $value = $obj->{$key};

        if (! defined $value) {
            next;
        }
        elsif (ref($value) eq 'ARRAY') {
            foreach (@$value) {
                my $field = WebService::Solr::Field->new($key => $_);
                push(@fields, $field);
            }
        }
        elsif (ref($value) eq 'HASH') {
            foreach (values %{flatten($value)}) {
                my $field = WebService::Solr::Field->new($key => $_);
                push(@fields, $field);
            }
        }
        else {
            my $field = WebService::Solr::Field->new($key => $value);
            push(@fields, $field);
        }
    }

    my $document = WebService::Solr::Document->new(@fields);

    $self->_push_stack($document);

    if ($self->_count_stack == $self->maxdoc) {
        $self->_save;
    }

    $obj;
}

sub _save {
    my $self = shift;
    
    $self->_indexer->add($self->_stack);
    $self->_stack([]);
}

sub delete {
    my ($self,$obj) = @_;
    my $id_field = $self->id_field;

    my $id = ref $obj eq 'HASH' ? $obj->{$id_field} :
                                  $obj;

    $id or confess "Missing $id_field";

    $self->_indexer->delete({ $id_field => $id });
}

sub commit {
    my ($self) = @_;

    $self->_save;
    $self->_indexer->commit;
}

sub search {
    my ($self,$query,%opts) = @_;

    $self->commit;

    my $start = $opts{start};
    my $limit = $opts{limit};

    my $response = $self->_indexer->search($query, {start => $start , rows => $limit});

    my $docs = $response->content->{response}->{docs};
    my $hits = $response->content->{response}->{numFound};
    my $objs = [];

    if (my $store = $opts{reify}) {
        my $id_field = $self->id_field;
        foreach my $hit (@$docs) {
            push @$objs, $store->load_strict($hit->{$id_field});
        }
    } 
    else {
        $objs = $docs;
    }

    return $objs, $hits;
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

__END__

=head1 NAME

Catmandu::Index::Solr - an implementation of L<Catmandu::Index> backed by L<WebService::Solr>.

=head1 SYNOPSIS

    use Catmandu::Index::Solr

    my $index = Catmandu::Index::Solr->new(url => 'http://localhost:8983/solr');

=head1 DESCRIPTION

See L<Catmandu::Index>.

=head1 METHODS

See L<Catmandu::Index> for the base methods.

Extra methods for this class:

=head2 Class->new(%args)

Takes the following arguments:

url: The url to the L<Solr> index (required). The url shouldn't contain the 'select|update' subpaths.

=head2 $c->url

Returns the url to the L<Solr> index files as a string.

=head1 SEE ALSO

L<Catmandu::Index>, the Index role.

L<WebService::Solr>, the underlying search engine.

