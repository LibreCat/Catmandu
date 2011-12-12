package Dancer::Session::Catmandu;

our $VERSION = '0.01';

use Catmandu::Sane;
use Catmandu;
use parent qw(Dancer::Session::Abstract);
use Dancer qw(:syntax setting);

my $bag;

sub init {
    my ($class) = @_;
    $bag ||= Catmandu::store(setting('session_store') || Catmandu::default_store)
        ->bag(setting('session_bag') || 'session');
    $class->SUPER::init;
}

sub create {
    my ($class) = @_;
    $class->new->flush;
}

sub retrieve {
    my ($class, $id) = @_;
    my $data = $bag->get($id) || return;
    $data->{id} = delete $data->{_id};
    bless $data, $class;
}

sub flush {
    my ($self) = @_;
    my $data = {%$self};
    $data->{_id} = delete $data->{id};
    $bag->add($data);
    $self;
}

sub destroy {
    my ($self) = @_;
    $bag->delete($self->{id});
}

1;
