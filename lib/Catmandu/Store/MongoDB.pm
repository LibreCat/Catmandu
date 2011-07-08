package Catmandu::Store::MongoDB;
use Catmandu::Sane;
use MongoDB;
use parent qw(Catmandu::Store);
use Catmandu::Object
    connection_args => 'r',
    db_name => 'r',
    connection => { default => '_build_connection' },
    db => { default => '_build_db' };

sub default_connection_args {
    {};
}

sub _build_connection {
    my $self = $_[0];
    MongoDB::Connection->new($self->connection_args);
}

sub _build_db {
    my $self = $_[0];
    $self->connection->get_database($self->db_name);
}

sub _build {
    my ($self, $args) = @_;
    $self->SUPER::_build($args);
    $self->{db_name} = $args->{db};
    $self->{connection_args} = $self->default_connection_args;
    if (my $ref = $args->{connection}) {
        for my $key (keys %$ref) {
            $self->{connection_args}{$key} = $ref->{$key};
        }
    }
}

package Catmandu::Store::MongoDB::Collection;
use Catmandu::Sane;
use parent qw(Catmandu::Collection);
use Catmandu::Object collection => { default => '_build_collection' };

sub _build_collection {
    my $self = $_[0];
    $self->store->db->get_collection($self->name);
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
    return;
}

1;
