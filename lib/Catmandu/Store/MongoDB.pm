package Catmandu::Store::MongoDB;
# ABSTRACT: A Catmandu::Store backed by MongoDB
# VERSION
use Moose;
use Data::UUID;
use Clone ();
use MongoDB;

with qw(Catmandu::Store);

has connection_args => (is => 'ro', isa => 'HashRef', required => 1);
has connection      => (is => 'ro', lazy => 1, builder => '_build_connection');
has db_name         => (is => 'ro', isa => 'Str', required => 1);
has db              => (is => 'ro', lazy => 1, builder => '_build_db');
has collection_name => (is => 'ro', isa => 'Str', required => 1);
has collection      => (is => 'ro', lazy => 1, builder => '_build_collection');

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args = $class->$orig(@args);
    $args->{connection_args} ||= Clone::clone($class->default_connection_args);
    $args;
};

sub default_connection_args {
    {};
}

sub _build_connection {
    my $self = shift; MongoDB::Connection->new($self->connection_args);
}

sub _build_db {
    my $self = shift; $self->connection->get_database($self->db_name);
}

sub _build_collection {
    my $self = shift;
    $self->db->get_collection($self->collection_name);
}

sub load {
    my ($self, $id) = @_;
    $self->collection->find_one({_id => $self->need_id($id)});
}

sub each {
    my ($self, $sub) = @_;
    my $cursor = $self->collection->find;
    my $n = 0;
    while (my $obj = $cursor->next) {
        $sub->($obj);
        $n++;
    }
    $n;
}

sub save {
    my ($self, $obj) = @_;
    my $id = $obj->{$self->id_field} ||= Data::UUID->new->create_str;
    $self->collection->save($obj);
    $obj;
}

sub delete {
    my ($self, $id) = @_;
    $self->collection->remove({_id => $self->need_id($id)});
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

