package Catmandu::Store::MongoDB;
use Catmandu::Sane;
use MongoDB;
use parent qw(Catmandu::Store);
use Catmandu::Object
    db_name => 'r',
    collection_name => 'r',
    connection_args => { default => sub { {} } },
    connection => { default => '_build_connection' },
    db         => { default => '_build_db' },
    collection => { default => '_build_collection' };

sub _build_connection {
    my $self = $_[0];
    MongoDB::Connection->new($self->connection_args);
}

sub _build_db {
    my $self = $_[0];
    $self->connection->get_database($self->db_name);
}

sub _build_collection {
    my $self = $_[0];
    $self->db->get_collection($self->collection_name);
}

sub _build {
    my ($self, $args) = @_;
    $self->{db_name} = delete($args->{db});
    $self->{collection_name} = delete($args->{collection});
    $self->{connection_args} = delete($args->{connection}) || $args;
    $self->SUPER::_build($args);
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

sub _get {
    my ($self, $id) = @_;
    $self->collection->find_one({_id => $id});
}

sub _add {
    my ($self, $obj) = @_;
    $self->collection->save($obj);
    $obj;
}

sub delete {
    my ($self, $id) = @_;
    $self->collection->remove({_id => $id});
}

1;
