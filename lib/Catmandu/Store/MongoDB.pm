package Catmandu::Store::MongoDB;
use Catmandu::Sane;
use MongoDB;
use parent qw(Catmandu::Store);
use Catmandu::Object
    database_name => 'r',
    collection_name => 'r',
    connection => { default => '_build_connection' },
    database => { default => '_build_database' },
    collection => { default => '_build_collection' };

sub default_connection_args {
    {};
}

sub allowed_connection_args {
    state $allowed_connection_args = [qw(
        host
        w
        wtimeout
        auto_reconnect
        auto_connect
        timeout
        username
        password
        db_name
        query_time
        max_bson_size
        find_master
    )];
}

sub _build_connection {
    MongoDB::Connection->new($_[0]->{connection_args});
}

sub _build_database {
    my $self = $_[0];
    $self->connection->get_database($self->database_name);
}

sub _build_collection {
    my $self = $_[0];
    $self->connection->get_database($self->database_name)->get_collection($self->collection_name);
}

sub _build {
    my ($self, $args) = @_;
    $self->{database_name} = $args->{database};
    $self->{collection_name} = $args->{collection};
    if (blessed $args->{connection}) {
        $self->{connection} = $args->{connection};
    } else {
        $self->{connection_args} = $self->default_connection_args;
        if (my $hash = $args->{connection}) {
            my $keys = $self->allowed_connection_args;
            for my $key (@$keys) {
                $self->{connection_args}{$key} = $hash->{$key} if exists $hash->{$key};
            }
        }
    }
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
