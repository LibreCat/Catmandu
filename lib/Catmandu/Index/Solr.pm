package Catmandu::Index::Solr;

use Moose;
use WebService::Solr;
use WebService::Solr::Field;
use WebService::Solr::Document;

with 'Catmandu::Index';

has path => (is => 'ro', isa => 'Str', required => 1);

has id_term => (is => 'ro', isa => 'Str', default => '_id');

has _indexer => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_indexer',
    predicate => '_has_indexer',
    clearer => '_clear_indexer',
);

sub _build_indexer {
    my $self = shift;
    WebService::Solr->new($self->path, { default_params => { wt => 'json' }});
}

sub save {
    my ($self,$obj) = @_;
    my $id_term = $self->id_term;

    $obj->{$id_term} or confess "Missing $id_term";

    my @fields = ();

    foreach my $key (keys %$obj) {
        my $value = $obj->{$key};
        my $field = WebService::Solr::Field->new($key => $value);
        push(@fields, $field);
    }

    my $document = WebService::Solr::Document->new(@fields);

    $self->_indexer->add($document) ? $obj : undef;
}

sub delete {
    my ($self,$obj) = @_;
    my $id_term = $self->id_term;

    my $id = ref $obj eq 'HASH' ? $obj->{$id_term} :
                                  $obj;

    $id or confess "Missing $id_term";

    $self->_indexer->delete({ $id_term => $id });
}

sub commit {
    my ($self) = @_;

    $self->_indexer->commit;
}

sub search {
    my ($self,$query,%opts) = @_;

    $self->commit;

    my $response = $self->_indexer->search($query);

    return $response->content->{response}->{docs}, 
           $response->content->{response}->{numFound};
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;
