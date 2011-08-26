package Dancer::Session::Catmandu;
our $VERSION = '0.01';
use Catmandu::Sane;
use Catmandu;
use parent qw(Dancer::Session::Abstract);
use Dancer::Config qw(setting);

my $collection;

sub init {
    my ($class) = @_;
    my $session_store = setting('session_store') || 'default';
    my $session_collection = setting('session_collection') || 'sessions';
    $collection = Catmandu::get_store($session_store)->collection($session_collection);
    $class->SUPER::init;
}

sub create {
    my ($class) = @_;
    $class->new->flush;
}

sub retrieve {
    my ($class, $id) = @_;
    my $obj = $collection->get($id) || return;
    $obj->{id} = delete $obj->{_id};
    delete $obj->{_collection};
    bless $obj, $class;
}

sub flush {
    my ($self) = @_;
    my $obj = {%$self};
    $obj->{_id} = delete $obj->{id};
    $collection->add($obj);
    $self;
}

sub destroy {
    my ($self) = @_;
    $collection->delete($self->{id});
}

1;
