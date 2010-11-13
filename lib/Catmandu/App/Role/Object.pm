package Catmandu::App::Role::Object;

use 5.010;
use Moose::Role;
use Catmandu;
use Catmandu::App::Request;
use Router::Simple;

has request => (
    is => 'ro',
    required => 1,
    handles => [qw(
        env
    )],
);

has response => (
    is => 'ro',
    lazy => 1,
    builder => '_build_response',
    handles => [qw(
        redirect
    )],
);

has params => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1, 
    default => sub { +{} },
);

sub _build_response {
    $_[0]->request->new_response(200, ['Content-Type' => "text/html"]);
}

sub req { $_[0]->request }
sub res { $_[0]->response }

sub session {
    $_[0]->request->env->{'psgix.session'};
}

sub param {
    my $self = shift;
    my $params = $self->params;
    return $params          if @_ == 0;
    return $params->{$_[0]} if @_ == 1;
    my %pairs = @_;
    while (my ($key, $val) = each %pairs) {
        $params->{$key} = $val;
    }
    $params;
}

sub print {
    my $self = shift;
    my $body = $self->response->body // [];
    push(@$body, @_);
    $self->response->body($body);
}

sub print_template {
    Catmandu->print_template($_[1], $_[2] // {}, $_[0]);
}

sub stash {
    my $class = ref $_[0] ? ref shift : shift;
    my $stash = Catmandu->stash->{$class} ||= {};
    return $stash          if @_ == 0;
    return $stash->{$_[0]} if @_ == 1;
    my %pairs = @_;
    while (my ($key, $val) = each %pairs) {
        $stash->{$key} = $val;
    }
    $stash;
}

sub run {
    my ($self, $sub) = @_;
    $sub //= $self->param('_run');
    if (ref $sub eq 'CODE') {
        $sub->($self);
    } else {
        $self->$sub();
    }
    $self;
}

sub route {
    $_[0]->stash->{_route} ||= Router::Simple->new;
}

sub add_route {
    $_[0]->route->connect($_[1], { _run => $_[2] }, $_[3] || {});
}

sub as_psgi_app {
    my $class = ref $_[0] ? ref shift : shift;
    my $route = $class->route;
    sub {
        my $env   = $_[0];
        my $match = $route->match($env)
            or return [ 404, ['Content-Type' => "text/plain"], ["Not Found"] ];
        $class->new(request => Catmandu::App::Request->new($env), params => $match)
            ->run($match->{_run})
            ->response->finalize;
    }
}

no Moose::Role;
__PACKAGE__;

