package Catmandu::Store::MongoDB;
use Catmandu::Sane;
use Catmandu::Util qw(quack ensure_id assert_id);
use MongoDB;
use Catmandu::Object
    db_name => 'r',
    collection_name => 'r',
    connection_args => { default => sub { {} } },
    connection => { default => '_build_connection' },
    db => { default => '_build_db' },
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
}

sub get {
    my ($self, $id) = @_;
    $self->collection->find_one({_id => assert_id($id)});
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

sub _add_obj {
    my ($self, $obj) = @_;
    ensure_id($obj);
    $self->collection->save($obj);
    $obj;
}

sub add {
    my ($self, $obj) = @_;
    if (quack $obj, 'each') {
        $obj->each(sub { $self->_add_obj($_[0]) });
    } else {
        $self->_add_obj($obj);
    }
}

sub delete {
    my ($self, $id) = @_;
    $self->collection->remove({_id => assert_id($id)});
}

1;
