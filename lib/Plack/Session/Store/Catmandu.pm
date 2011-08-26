package Plack::Session::Store::Catmandu;
our $VERSION = '0.01';
use Catmandu::Sane;
use Catmandu;
use parent qw(Plack::Session::Store);

sub new {
    my ($class, %opts) = @_;
    my $store = $opts{store} || 'default';
    my $collection = $opts{collection} || 'sessions';
    bless {
        collection => Catmandu::get_store($store)->collection($collection),
    }, $class;
}

sub fetch {
    my ($self, $id) = @_;
    my $obj = $self->{collection}->get($id) || return;
    delete $obj->{_id};
    delete $obj->{_collection};
    $obj;
}

sub store {
    my ($self, $id, $obj) = @_;
    $obj->{_id} = $id;
    $self->{collection}->add($obj);
    delete $obj->{_id};
    $obj;
}

sub remove {
    my ($self, $id) = @_;
    $self->{collection}->delete($id);
}

1;
