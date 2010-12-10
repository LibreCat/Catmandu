package Catmandu::App::Router::Route;

use namespace::autoclean;
use Moose;

has app => (
    is => 'ro',
    required => 1,
);

has sub => (
    is => 'ro',
    isa => 'CodeRef|Str',
    required => 1,
);

has path => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has components => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        _add_component => 'push',
    },
);

has defaults => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);

has methods => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        method_list => 'elements',
        has_methods => 'count',
    },
);

has _re_path    => (is => 'rw', isa => 'RegexpRef');
has _re_methods => (is => 'rw', isa => 'RegexpRef');

sub BUILD {
    my $self = shift;

    my $path = $self->path;

    if ($self->has_methods) {
        my $methods = join '|', $self->method_list;
        $self->_re_methods(qr/^(?:$methods)$/);
    }

    $path =~ s!
        \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
        :([A-Za-z0-9_]+)              | # /blog/:year
        (\*)                          | # /blog/*/*
        ([^{:*]+)                       # normal string
    !
        if ($1) {
            my ($name, $re) = split /:/, $1, 2;
            $self->_add_component($name);
            $re ? "($re)" : "([^/]+)";
        } elsif ($2) {
            $self->_add_component($2);
            "([^/]+)";
        } elsif ($3) {
            $self->_add_component('__splat__');
            "(.+)";
        } else {
            quotemeta($4);
        }
    !gex;
    $self->_re_path(qr/^$path$/);
}

sub match {
    my ($self, $env) = @_;

    my $components = $self->components;

    if (my $re = $self->_re_methods) {
        return if ($env->{REQUEST_METHOD} || '') !~ $re;
    }

    if (my @captures = ($env->{PATH_INFO} =~ $self->_re_path)) {
        my %params;
        my @splat;
        for my $i (0..@$components-1) {
            if ($components->[$i] eq '__splat__') {
                push @splat, $captures[$i];
            } else {
                $params{$components->[$i]} = $captures[$i];
            }
        }
        return {
            %{$self->defaults},
            %params,
            ( @splat ? ( splat => \@splat ) : () ),
        };
    }
    return;
}

sub named {
    ! ref $_[0]->sub;
}

sub anonymous {
    ! $_[0]->named;
}

__PACKAGE__->meta->make_immutable;

package Catmandu::App::Router;

use namespace::autoclean;
use Moose;
use List::Util qw(max);
use overload q("") => \&stringify;

has routes => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[Catmandu::App::Router::Route]',
    default => sub { [] },
    handles => {
        route_list => 'elements',
        add_routes => 'push',
        has_routes => 'count',
    },
);

sub steal_routes {
    my ($self, $path, $router, $defaults) = @_;

    confess "Malformed path: path must start with a slash" if $path !~ /^\//;

    $defaults ||= {};

    $self->add_routes(map {
        Catmandu::App::Router::Route->new(
            app => $_->app,
            sub => $_->sub,
            methods => $_->methods,
            defaults => { %{$_->defaults}, %$defaults },
            path => $path . $_->path,
        );
    } $router->route_list);
    $self;
}

sub route {
    my $self = shift;
    $self->add_routes(Catmandu::App::Router::Route->new(@_));
    $self;
}

sub match {
    my ($self, $env) = @_;

    $env = { PATH_INFO => $env } unless ref $env;

    for my $route ($self->route_list) {
        my $match = $route->match($env);
        return $match, $route if $match;
    }
    return;
}

sub stringify {
    my $self = shift;

    my $max_a = max(map { length $_->app } $self->route_list);
    my $max_m = max(map { length join(',', $_->method_list) } $self->route_list);
    my $max_s = max(map { $_->named ? length $_->sub : 7 } $self->route_list);

    join '', map {
        sprintf "%-${max_a}s %-${max_m}s %-${max_s}s %s\n",
            $_->app,
            join(',', $_->method_list),
            $_->named ? $_->sub : 'CODEREF',
            $_->path;
    } $self->route_list;
}

__PACKAGE__->meta->make_immutable;

1;

