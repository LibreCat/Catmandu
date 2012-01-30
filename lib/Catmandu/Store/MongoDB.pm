package Catmandu::Store::MongoDB;

use Catmandu::Sane;
use Moo;
use MongoDB;

with 'Catmandu::Store';

my $CONNECTION_ARGS = [qw(
    host
    w
    wtimeout
    auto_reconnect
    auto_connect
    timeout
    username
    password
    db_name
    query_timeout
    max_bson_size
    find_master
)];

has connection    => (is => 'ro', lazy => 1, builder => '_build_connection');
has database_name => (is => 'ro', required => 1);
has database      => (is => 'ro', lazy => 1, builder => '_build_database');

sub _build_connection {
    MongoDB::Connection->new(delete $_[0]->{_args});
}

sub _build_database {
    my $self = $_[0]; $self->connection->get_database($self->database_name);
}

sub BUILD {
    my ($self, $args) = @_;
    $self->{_args} = {};
    for my $key (@$CONNECTION_ARGS) {
        $self->{_args}{$key} = $args->{$key} if exists $args->{$key};
    }
}

package Catmandu::Store::MongoDB::Bag;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Bag';

has collection => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_collection',
);

sub _build_collection {
    $_[0]->store->database->get_collection($_[0]->name);
}

sub generator {
    my ($self) = @_;
    sub {
        state $cursor = $self->collection->find;
        $cursor->next || return;
    };
}

sub each {
    my ($self, $sub) = @_;
    my $cursor = $self->collection->find;
    my $n = 0;
    while (my $data = $cursor->next) {
        $sub->($data);
        $n++;
    }
    $n;
}

sub count {
    $_[0]->collection->count;
}

sub get {
    my ($self, $id) = @_;
    $self->collection->find_one({_id => $id});
}

sub add {
    my ($self, $data) = @_;
    $self->collection->save($data);
}

sub delete {
    my ($self, $id) = @_;
    $self->collection->remove({_id => $id});
}

sub delete_all {
    my ($self) = @_;
    $self->collection->remove({});
}

1;
