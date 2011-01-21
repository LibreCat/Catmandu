package Catmandu::App::Router;
# ABSTRACT: HTTP router
# VERSION
use Moose;
use Catmandu::App::Router::Route;
use Hash::Merge::Simple qw(merge);
use List::Util qw(max);

use overload q("") => sub { $_[0]->stringify };

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
    my ($self, $pattern, $router, $defaults) = @_;

    confess "Pattern can't be empty" if ! $pattern;
    confess "Pattern must start with a slash" if $pattern !~ /^\//;
    confess "Pattern can't end with a slash" if $pattern =~ /\/$/;

    $defaults ||= {};

    $self->add_routes(map {
        Catmandu::App::Router::Route->new(
            app => $_->app,
            sub => $_->sub,
            pattern => $pattern . $_->pattern,
            defaults => merge($_->defaults, $defaults),
            methods => $_->methods,
        );
    } $router->route_list);
    $self;
}

sub route {
    my ($self, $pattern, %opts) = @_;
    $self->add_routes(Catmandu::App::Router::Route->new(%opts, pattern => $pattern));
    $self;
}

sub match {
    my ($self, $env) = @_;

    ref $env or $env = { PATH_INFO => $env };

    my $code = 404;

    for my $route ($self->route_list) {
        my ($match, $c) = $route->match($env);
        if ($match) {
            return $match, $route, $c;
        } elsif ($code == 404 && $c != 404) {
            $code = $c;
        }
    }

    return undef, undef, $code;
}

sub stringify {
    my $self = shift;

    my $max_a = max(map { length ref $_->app } $self->route_list);
    my $max_m = max(map { length join(',', $_->method_list) } $self->route_list);
    my $max_s = max(map { $_->named ? length $_->sub : 7 } $self->route_list);

    join '', map {
        sprintf "%-${max_a}s %-${max_m}s %-${max_s}s %s\n",
            ref $_->app,
            join(',', $_->method_list),
            $_->named ? $_->sub : 'CODEREF',
            $_->pattern;
    } $self->route_list;
}

__PACKAGE__->meta->make_immutable;

no Moose;
no Hash::Merge::Simple;
no List::Util;

1;

