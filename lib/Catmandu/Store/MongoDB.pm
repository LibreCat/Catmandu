package Catmandu::Store::MongoDB;
use Data::UUID;
use MongoDB;
use Catmandu::Class qw(connection db collection);
use parent qw(
    Catmandu::Modifiable
    Catmandu::Pluggable
);

sub plugin_namespace { 'Catmandu::Store::Plugin' }

sub build {
    my ($self, $args) = @_;

    my $collection = delete($args->{collection}) || confess("Attribute collection is required");
    my $db = delete($args->{db}) || confess("Attribute db is required");

    $self->{connection} = $args->{connection} || MongoDB::Connection->new($args);
    $self->{db} = $self->connection->get_database($db);
    $self->{collection} = $self->db->get_collection($collection);
}

sub load {
    my ($self, $id) = @_;
    $id = $id->{_id} if ref $id eq 'HASH';
    $id or confess "_id missing";
    $self->collection->find_one({_id => $id});
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
    $obj->{_id} ||= Data::UUID->new->create_str;
    $self->collection->save($obj, {safe => 1});
    $obj;
}

sub delete {
    my ($self, $id) = @_;
    $id = $id->{_id} if ref $id eq 'HASH';
    $id or confess "_id missing";
    $self->collection->remove({_id => $id}, {safe => 1});
}

1;
