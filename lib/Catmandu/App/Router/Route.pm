package Catmandu::App::Router::Route;
# ABSTRACT: HTTP route
# VERSION
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

has path_parts => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[Str|HashRef]',
    default => sub { [] },
    handles => {
        _add_path_part => 'push',
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

    $path =~ s!
        \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
        :([A-Za-z0-9_]+)              | # /blog/:year
        (\*)                          | # /blog/*/*
        ([^{:*]+)
    !
        if ($1) {
            my ($name, $re) = split /:/, $1, 2;
            $self->_add_path_part({key => $name});
            $self->_add_component($name);
            $re ? "($re)" : "([^/]+)";
        } elsif ($2) {
            $self->_add_path_part({key => $2});
            $self->_add_component($2);
            "([^/]+)";
        } elsif ($3) {
            $self->_add_path_part({});
            $self->_add_component('__splat__');
            "(.+)";
        } else {
            $self->_add_path_part($4);
            quotemeta($4);
        }
    !gex;
    $self->_re_path(qr/^$path$/);

    if ($self->has_methods) {
        my $methods = join '|', $self->method_list;
        $self->_re_methods(qr/^(?:$methods)$/);
    }
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

1;

