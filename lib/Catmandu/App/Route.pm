package Catmandu::App::Route;
# ABSTRACT: HTTP route
# VERSION
use 5.010;
use Moose;
use Hash::MultiValue;
use URI;
use URI::QueryParam;

has app => (
    is => 'ro',
    required => 1,
);

has sub => (
    is => 'ro',
    isa => 'CodeRef|Str',
    required => 1,
);

has pattern => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has parts => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[Str|HashRef]',
    default => sub { [] },
    handles => {
        _add_part => 'push',
    },
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
    lazy => 1,
    default => sub { {} },
    predicate => 'has_defaults',
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

has _pattern_regex => (is => 'rw', isa => 'RegexpRef');
has _methods_regex => (is => 'rw', isa => 'RegexpRef');

sub BUILD {
    my $self = shift;

    my $pattern = $self->pattern;

    $pattern =~ s!
        \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
        :([A-Za-z0-9_]+)              | # /blog/:year
        (\*)                          | # /blog/*/*
        ([^{:*]+)
    !
        if ($1) {
            my ($name, $re) = split /:/, $1, 2;
            $self->_add_part({key => $name});
            $self->_add_component($name);
            $re ? "($re)" : "([^/]+)";
        } elsif ($2) {
            $self->_add_part({key => $2});
            $self->_add_component($2);
            "([^/]+)";
        } elsif ($3) {
            $self->_add_part({key => 'splat'});
            $self->_add_component('splat');
            "(.+)";
        } else {
            $self->_add_part($4);
            quotemeta($4);
        }
    !gex;

    $self->_pattern_regex(qr/^$pattern$/);

    if ($self->has_methods) {
        my $methods = join '|', $self->method_list;
        $self->_methods_regex(qr/^(?:$methods)$/);
    }
}

sub match {
    my ($self, $env) = @_;

    my @captures = $env->{PATH_INFO} =~ $self->_pattern_regex or return undef, 404;

    if (my $re = $self->_methods_regex) {
        ($env->{REQUEST_METHOD} || "") =~ $re or return undef, 405;
    }

    my $parameters = Hash::MultiValue->new;
    my $components = $self->components;

    for my $i (0..@$components-1) {
        $parameters->add($components->[$i], $captures[$i]);
    }

    if ($self->has_defaults) {
        my $defaults = $self->defaults;
        for my $key (keys %$defaults) {
            $parameters->get($key) // $parameters->add($defaults->{$key});
        }
    }

    return $parameters, 200;
}

sub anonymous {
    !! ref $_[0]->sub;
}

sub named {
    ! ref $_[0]->sub;
}

sub path_for {
    my ($self, $opts) = @_;

    while (my ($key, $val) = each %{$self->defaults}) {
        $opts->{$key} //= $val;
    }

    my $splats = $opts->{splat} || [];

    my $path = "";

    for my $part (@{$self->parts}) {
        if (ref $part) {
            if ($part->{key} ne 'splat') {
                $path .= delete($opts->{$part->{key}}) // return;
            } else {
                $path .= shift(@$splats) // return;
            }
        } else {
            $path .= $part;
        }
    }

    if (%$opts) {
        my $uri = URI->new("", "http");
        $uri->query_param(%$opts);
        $path .= "?";
        $path .= $uri->query;
    }

    $path;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

