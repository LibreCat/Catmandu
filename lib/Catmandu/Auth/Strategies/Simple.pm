package Catmandu::Auth::Strategies::Simple;

use Moose;

with 'Catmandu::Auth::Strategy';

has username_param => (is => 'ro', isa => 'Str', default => 'username');
has password_param => (is => 'ro', isa => 'Str', default => 'password');
has load_user => (is => 'ro', isa => 'CodeRef', required => 1);
has auth => (is => 'ro', required => 1);

sub can_authenticate {
    my $self = shift;
    my $params = $self->request->parameters;
    $params->{$self->username_param} || $params->{$self->password_param};
}

sub authenticate {
    my $self = shift;
    my $params = $self->request->parameters;
    my $user = $params->{$self->username_param};
    my $pass = $params->{$self->password_param};
    my $auth = $self->auth;

    if (ref $auth eq 'CODE' ? $auth->($user, $pass) :
                              $auth->authenticate($user, $pass)) {
        $self->success($self->load_user->($user));
    } else {
        $self->failure;
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

