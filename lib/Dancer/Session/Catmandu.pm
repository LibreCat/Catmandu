package Dancer::Session::Catmandu;

our $VERSION = '0.01';

use Catmandu::Sane;
use Catmandu;
use parent qw(Dancer::Session::Abstract);
use Dancer qw(:syntax config);

my $bag;

sub init {
    $bag ||= Catmandu::store(config->{session_store} || Catmandu::default_store)
        ->bag(config->{session_bag} || 'session');
    $_[0]->SUPER::init;
}

sub create {
    $_[0]->new->flush;
}

sub retrieve {
    my $data = $bag->get($_[1]) || return;
    $data->{id} = delete $data->{_id};
    bless $data, $_[0];
}

sub flush {
    my $self = $_[0];
    my $data = {%$self};
    $data->{_id} = delete $data->{id};
    $bag->add($data);
    $self;
}

sub destroy {
    $bag->delete($_[0]->{id});
}

1;
