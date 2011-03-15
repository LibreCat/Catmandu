package Catmandu::Authentication::Strategy::Password;
use parent qw(
    Catmandu::Authentication::Strategy
);
use Catmandu::Class qw(
    load_user
    auth
);

my $username_param = 'username';
my $password_param = 'password';

sub can_authenticate {
    my $self = $_[0];
    my $params = $self->request->parameters;
    $params->{$username_param} && $params->{$password_param};
}

sub authenticate {
    my $self = $_[0];
    my $params = $self->request->parameters;
    my $user = $params->{$username_param};
    my $pass = $params->{$password_param};
    my $auth = $self->auth;

    if (ref $auth eq 'CODE' ? $auth->($user, $pass) : $auth->authenticate($user, $pass)) {
        $self->success($self->load_user->($user));
    } else {
        $self->failure;
    }
}

1;

