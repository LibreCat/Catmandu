package Catmandu::Store::SBCatDB;
use Catmandu::Sane;
use SBCatDB;
use Catmandu::Util qw(opts);
use parent qw(Catmandu::Store);
use Catmandu::Object
    db => { default => '_build_db' };

sub _build_connection {
    my $self = $_[0];
    SBCatDB->new($self->db_args);
}

sub _build_db {
    my $self = $_[0];
    SBCatDB->new($self->connection_args);
}


sub _build_args {
    my ($self, @args) = @_;
    my $args = opts @args;
    $args;
}

package Catmandu::Store::SBCatDB::Collection;
use Catmandu::Sane;
use parent qw(Catmandu::Collection);
#use Catmandu::Object collection => { default => '_build_collection' };


sub each {
    my ($self, $sub) = @_;
    my $results = $self->store->db->find; 
    my $n = 0;
    while (my $obj = $results->next) {
        $sub->($obj);
        $n++;
    }
    $n;
}

sub _get {
    my ($self, $id) = @_;
    $self->store->db->get($id);
}

sub _add {
    my ($self, $obj) = @_;
    $self->store->db->save($obj);
    $obj;
}

sub delete {
    my ($self, $id) = @_;
    $self->store->db->remove($id);
    return;
}

1;
