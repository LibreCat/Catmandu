package Catmandu::Auth::Strategy;

use Moose::Role;

with 'Catmandu::App::Env';

requires 'can_authenticate';
requires 'authenticate';

has has_run => (is => 'rw', isa => 'Bool', default => 0);
has halts   => (is => 'rw', isa => 'Bool', default => 0);
has store   => (is => 'rw', isa => 'Bool', default => 1);
has scope   => (is => 'ro', isa => 'Str');
has user    => (is => 'rw');
has message => (is => 'rw');
has result  => (is => 'rw');
has custom_response => (is => 'rw', isa => 'ArrayRef');

sub run {
    my $self = shift;
    $self->authenticate;
    $self->has_run(1);
    $self;
}

sub rerun {
    my $self = shift;
    $self->has_run(0);
    $self;
}

sub pass {
    # do nothing
    $_[0];
}

sub halt {
    my $self = shift;
    $self->halts(1);
    $self;
}

sub success {
    my ($self, $user, $msg) = @_;
    $self->halts(1);
    $self->user($user);
    $self->message($msg) if $msg;
    $self->result('success');
    $self;
}

sub failure_and_halt {
    my ($self, $msg) = @_;
    $self->halts(1);
    $self->message($msg) if $msg;
    $self->result('failure');
    $self;
}

sub failure {
    my ($self, $msg) = @_;
    $self->message($msg) if $msg;
    $self->result('failure');
    $self;
}

sub respond {
    my ($self, $res) = @_;
    $self->halts(1);
    $self->custom_response($res);
    $self->result('custom');
    $self;
}

no Moose::Role;
__PACKAGE__;

