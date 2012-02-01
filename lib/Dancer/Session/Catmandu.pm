package Dancer::Session::Catmandu;

our $VERSION = '0.01';

use Catmandu::Sane;
use Catmandu;
use parent qw(Dancer::Session::Abstract);
use Dancer qw(:syntax config);

sub _bag {
    state $bag = Catmandu::store(config->{session_store} || Catmandu::default_store)
        ->bag(config->{session_bag} || 'session');
}

sub init {
    $_[0]->SUPER::init;
}

sub create {
    $_[0]->new->flush;
}

sub retrieve {
    my $data = _bag->get($_[1]) || return;
    $data->{id} = delete $data->{_id};
    bless $data, $_[0];
}

sub flush {
    my $self = $_[0];
    my $data = {%$self};
    $data->{_id} = delete $data->{id};
    _bag->add($data);
    $self;
}

sub destroy {
    _bag->delete($_[0]->{id});
}

1;
