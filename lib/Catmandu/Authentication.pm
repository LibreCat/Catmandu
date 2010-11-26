package Catmandu::Authentication;

use 5.010;
use Moose;
use Catmandu::Err;
use Plack::Util;

with 'Catmandu::App::Env';

has app => (
    is => 'bare',
    required => 1,
    handles => [qw(
        default_strategies
        default_scope
        scopes
        from_session
        into_session
    )],
);

for (qw( _strategies _winning_strategies _users )) {
    has $_ => (
        is => 'rw',
        isa => 'HashRef',
        default => sub { +{} },
        init_arg => undef,
    );
}

has _winning_strategy => (
    is => 'rw',
    init_arg => undef,
);

my $SESSION_KEY = "catmandu.auth";

sub _get_user {
    my ($self, $scope) = @_;
    my $session_key = "$SESSION_KEY.$scope.key";
    my $session = $self->session;
    my $user_key = $session->{$session_key} or return;
    my $user = $self->from_session->($user_key);
    $user or delete $session->{$session_key};
    $user;
}

sub clear_user {
    my ($self, @scopes) = @_;
    my $all = !@scopes;

    if ($all) {
        push @scopes, keys %{$self->_users};
    }

    for my $scope (@scopes) {
        delete $self->session->{"$SESSION_KEY.$scope.session"};
        delete $self->session->{"$SESSION_KEY.$scope.key"};
        delete $self->_users->{$scope};
    }

    if ($all) {
        $self->clear_session;
    }
}

sub set_user {
    my ($self, $user, %opts) = @_;
    my $scope = $opts{scope} ||= $self->default_scope;

    if (my $default_opts = $self->scopes->{$scope}) {
        while (my ($key, $value) = each %$default_opts) {
            $opts{$key} //= $value;
        }
    }

    $self->_users->{$scope} = $user;

    if ($opts{store}) {
        $self->session->{"$SESSION_KEY.$scope.key"} = $self->into_session->($user);
    }

    $user;
}

sub user {
    my ($self, $scope) = @_;
    $scope ||= $self->default_scope;
    $self->_users->{$scope} ||= do {
        my $user = $self->_get_user($scope);
        $self->set_user($user, scope => $scope) if $user;
        $user;
    };
}

sub user_session {
    my ($self, $scope) = @_;
    $scope ||= $self->default_scope;
    $self->is_authenticated($scope) || return;
    $self->session->{"$SESSION_KEY.$scope.session"} ||= {};
}

sub message {
    my $self = shift;
    if ($self->_winning_strategy) {
        return $self->_winning_strategy->message;
    }
    return;
}

sub result {
    my $self = shift;
    if ($self->_winning_strategy) {
        return $self->_winning_strategy->result;
    }
    return;
}

sub custom_response {
    my $self = shift;
    if ($self->_winning_strategy) {
        return $self->_winning_strategy->custom_response;
    }
    return;
}

sub is_authenticated {
    my ($self, $scope) = @_;
    $scope ||= $self->default_scope;
    defined $self->user($scope);
}

sub authenticate {
    my $self = shift;
    my $user = $self->run_authentication(@_);
    $user || Catmandu::Err::HTTP->throw(401);
    $user;
}

sub run_authentication {
    my ($self, %opts) = @_;
    my $scope = $opts{scope} ||= $self->default_scope;

    $opts{strategies} ||= $self->scopes->{$scope}{strategies} || $self->default_strategies;

    my $user = $self->user($scope);

    if ($user) {
        return $user;
    }

    $self->_run_strategies(%opts);

    if ($self->_winning_strategy and $user = $self->_winning_strategy->user) {
        $opts{store} ||= $self->_winning_strategy->store;
        $self->set_user($user, %opts);
    }

    $self->_users->{$scope};
}

sub _run_strategies {
    my ($self, %opts) = @_;
    my $scope = $opts{scope};

    $self->_winning_strategy($self->_winning_strategies->{$scope});

    return if $self->_winning_strategy && 
              $self->_winning_strategy->halts;

    for my $key (@{$opts{strategies}}) {
        my $strategy = $self->_get_strategy($key, $scope);
        return if ! $strategy || $strategy->has_run || ! $strategy->can_authenticate;
        $self->_winning_strategies->{$scope} = $strategy;
        $self->_winning_strategy($strategy);
        $strategy->run;
        last if $strategy->halts;
    }
}

sub _get_strategy {
    my ($self, $key, $scope) = @_;
    $self->_strategies->{$scope}{$key} ||= do {
        my $class = "Catmandu::Authentication::Strategies::" . ucfirst($key);
        Plack::Util::load_class($class);
        $class->new(env => $self->env, scope => $scope);
    };

}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

