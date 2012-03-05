package Catmandu::Store::SBCatDB;

use Catmandu::Sane;
use Moo;
use SBCatDB;

with 'Catmandu::Store';

has db => (is => 'ro', builder => '_build_db');
has config_file => (is => 'ro', default => sub { '' });
has db_name  => (default =>  sub { 'luur' });
has sbcat_collection => (default => sub { 'publicationItem' });
has host     => (default => sub { '127.0.0.1' });
has username => (default => sub { 'lur' });
has password => (default => sub { '' });

sub _build_db {
    my $self = $_[0];
    SBCatDB->new({
        config_file => $self->config_file,
        db_name     => $self->db_name,
        host        => $self->host,
        username    => $self->username,
        password    => $self->password,
        collection  => $self->sbcat_collection,
    });
}

package Catmandu::Store::SBCatDB::Bag;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Bag';

sub generator {
    my $self = $_[0];
    sub {
        state $results = $self->store->db->find;
        $results->next;
    };
}

sub get {
    my ($self, $id) = @_;
    $self->store->db->get($id);
}

sub add {
    my ($self, $data) = @_;
    $self->store->db->save($data);
    $data;
}

sub delete {
    my ($self, $id) = @_;
    $self->store->db->remove($id);
}

sub delete_all {
    confess "TODO";
}

1;

