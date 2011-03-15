package Catmandu::Authentication::Strategy;
use Catmandu::Class qw(
    env
    has_run
    halts
    store
    scope
    user
    message
    result
    custom_response
);
use Plack::Request;

sub build {
    my ($self, $args) = @_;
    $self->SUPER::build($args);
    $self->{store} = 1;
}

sub can_authenticate {
    confess "Not implemented";
}

sub authenticate {
    confess "Not implemented";
}

sub request { $_[0]->{request} ||= Plack::Request->new($_[0]->env) }
sub req { $_[0]->request }

sub run {
    my $self = shift;
    $self->authenticate;
    $self->{has_run} = 1;
    $self;
}

sub rerun {
    my $self = shift;
    $self->{has_run} = 0;
    $self;
}

sub pass {
    # do nothing
    $_[0];
}

sub halt {
    my $self = shift;
    $self->{halts} = 1;
    $self;
}

sub success {
    my ($self, $user, $msg) = @_;
    $self->{halts} = 1;
    $self->{user} = $user;
    $self->{message} = $msg if $msg;
    $self->{result} = 'success';
    $self;
}

sub failure_and_halt {
    my ($self, $msg) = @_;
    $self->{halts} = 1;
    $self->{message} = $msg if $msg;
    $self->{result} = 'failure';
    $self;
}

sub failure {
    my ($self, $msg) = @_;
    $self->{message} = $msg if $msg;
    $self->{result} = 'failure';
    $self;
}

sub respond {
    my ($self, $res) = @_;
    $self->{halts} = 1;
    $self->{custom_response} = $res;
    $self->{result} = 'custom';
    $self;
}

1;
