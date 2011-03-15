package Catmandu::Authentication;
use Catmandu::Class qw(app env);
use Catmandu::Util;
use Catmandu::HTTP::Error;
use Plack::Request;

my $session_key = 'catmandu.authentication';
my $env_key = 'catmandu.authentication';

sub default_strategies { $_[0]->{app}->default_strategies }
sub default_scope      { $_[0]->{app}->default_scope }
sub strategies         { $_[0]->{app}->strategies }
sub scopes             { $_[0]->{app}->scopes }
sub into_session       { $_[0]->{app}->into_session }
sub from_session       { $_[0]->{app}->from_session }

sub _cached_strategies { $_[0]->{_cached_strategies} ||= {} }
sub _winning_strategies { $_[0]->{_winning_strategies} ||= {} }
sub _users { $_[0]->{_users} ||= {} }

sub _winning_strategy { 
    if ($_[1]) {
        $_[0]->{_winning_strategy} = $_[1];
    } else {
        $_[0]->{_winning_strategy};
    }
}

sub request { $_[0]->{request} ||= Plack::Request->new($_[0]->env) }
sub req { $_[0]->request }

sub session { $_[0]->env->{'psgix.session'} || confess("Session must be enabled") }

sub clear_session {
    my $session = $_[0]->session;
    foreach (keys %$session) {
        delete $session->{$_};
    }
    $session;
}

sub logout {
    my ($self, @scopes) = @_;
    my $all = !@scopes;

    if ($all) {
        push @scopes, keys %{$self->_users};
    }

    for my $scope (@scopes) {
        delete $self->session->{"$session_key.$scope.session"};
        delete $self->session->{"$session_key.$scope.key"};
        delete $self->_users->{$scope};
    }

    if ($all) {
        $self->clear_session;
    }
}

sub login {
    my ($self, $user, %opts) = @_;
    my $scope = $opts{scope} ||= $self->default_scope;

    if (my $default_opts = $self->scopes->{$scope}) {
        while (my ($key, $value) = each %$default_opts) {
            $opts{$key} //= $value;
        }
    }

    $self->_users->{$scope} = $user;

    if ($opts{store}) {
        $self->session->{"$session_key.$scope.key"} = $self->into_session->($user);
    }

    $user;
}

sub user {
    my ($self, $scope) = @_;
    $scope ||= $self->default_scope;

    $self->_users->{$scope} ||= do {
        my $session_key = "$session_key.$scope.key";
        my $key = $self->session->{$session_key};

        my $user;

        if ($key and $user = $self->from_session->($key)) {
            $self->login($user, scope => $scope)
        }

        if (! $user) {
            delete $self->session->{$session_key};
        }

        $user
    };
}

sub user_session {
    my ($self, $scope) = @_;
    $scope ||= $self->default_scope;
    $self->authenticated($scope) || return;
    $self->session->{"$session_key.$scope.session"} ||= {};
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

sub needs_authentication {
    my $self = shift;
    $self->authenticate(@_) or Catmandu::HTTP::Error->throw(401);
}

sub authenticated {
    my ($self, $scope) = @_;
    $scope ||= $self->default_scope;
    defined $self->user($scope);
}

sub authenticate {
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
        $self->login($user, %opts);
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
    $self->_cached_strategies->{$scope}{$key} ||= do {
        my $class = "Catmandu::Authentication::Strategy::" . ucfirst($key);
        Catmandu::Util::load_package($class);
        my $attrs = $self->strategies->{$key} || {};
        $class->new(%$attrs, env => $self->env, scope => $scope);
    };
}

1;

