use MooseX::Declare;

role Catmandu::App::Env {
    use Catmandu::App::Request;

    has env => (
        is => 'ro',
        isa => 'HashRef',
        required => 1,
    );

    has request => (
        is => 'ro',
        isa => 'Catmandu::App::Request',
        lazy => 1,
        builder => '_build_request',
    );

    method _build_request () {
        Catmandu::App::Request->new($self->env);
    }

    method req () {
        $self->request;
    }

    method session () {
        $self->env->{'psgix.session'};
    }

    method clear_session () {
        my $session = $self->session;
        for (keys %$session) {
            delete $session->{$_};
        }
        $session;
    }
}

1;

