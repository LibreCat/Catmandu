package Catmandu::Store::SBCatDB;
use Catmandu::Sane;
use SBCatDB;
use Catmandu::Util qw(opts);
use parent qw(Catmandu::Store);
use Catmandu::Object
    db => { default => '_build_db' },
    config_file => { default => sub { '' } },
    db_name  => { default =>  sub { 'luur' } },
    sbcat_collection => { default => sub { 'publicationItem' } },
    host     => { default =>  sub { '127.0.0.1'} },
    username => { default =>  sub { 'lur' } },
    password => { default => sub { '' } };
    ;

sub _build_db {
    my $self = $_[0];
    SBCatDB->new({
        config_file => $self->config_file,
        db_name     => $self->db_name,
        username    => $self->username,
        host        => $self->host,
        password    => $self->password,
        collection  => $self->sbcat_collection, 
        });
}


sub _build_args {
    my ($self, @args) = @_;
    my $args = opts @args;
    $args;
}

package Catmandu::Store::SBCatDB::Collection;
use Catmandu::Sane;
use parent qw(Catmandu::Collection);

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
