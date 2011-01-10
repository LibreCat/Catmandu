package Catmandu::App::Router;
# ABSTRACT: HTTP router
# VERSION
use namespace::autoclean;
use 5.010;
use Moose;
use Catmandu::App::Router::Route;
use URI;
use URI::QueryParam;
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

sub path_for {
    my $self = shift;
    my $name = shift;
    my $args = ref $_[-1] eq 'HASH' ? pop : { @_ };

    my ($route) = grep { $_->named and $_->sub eq $name } $self->route_list;

    if ($route) {
        while (my ($key, $val) = each %{$route->defaults}) {
            $args->{$key} //= $val;
        }

        my $splats = $args->{splat} || [];

        my $path = "";

        for my $part (@{$route->path_parts}) {
            if (ref $part) {
                if ($part->{key}) {
                    $path .= delete($args->{$part->{key}}) // return;
                } else {
                    $path .= shift(@$splats) // return;
                }
            } else {
                $path .= $part;
            }
        }

        if (%$args) {
            my $uri = URI->new("", "http");
            $uri->query_param(%$args);
            $path .= "?";
            $path .= $uri->query;
        }

        return $path;
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

