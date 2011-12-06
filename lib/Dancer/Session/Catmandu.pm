package Dancer::Session::Catmandu;

our $VERSION = '0.01';

use Catmandu::Sane;
use Catmandu;
use parent qw(Dancer::Session::Abstract);
use Dancer::Config qw(setting);

my $bag;

sub init {
    my ($class) = @_;
    $bag = Catmandu::store(setting('session_store'))->bag(setting('session_bag') || 'sessions');
    $class->SUPER::init;
}

sub create {
    my ($class) = @_;
    $class->new->flush;
}

sub retrieve {
    my ($class, $id) = @_;
    my $obj = $bag->get($id) || return;
    $obj->{id} = delete $obj->{_id};
    bless $obj, $class;
}

sub flush {
    my ($self) = @_;
    my $obj = {%$self};
    $obj->{_id} = delete $obj->{id};
    $bag->add($obj);
    $self;
}

sub destroy {
    my ($self) = @_;
    $bag->delete($self->{id});
}

1;
