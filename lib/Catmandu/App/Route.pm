package Catmandu::App::Route;
# ABSTRACT: HTTP route
# VERSION
use 5.010;
use Moose;

has app => (
    is => 'ro',
    required => 1,
    weak_ref => 1,
);

has handler => (
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

has pattern_regex => (is => 'rw', isa => 'RegexpRef', init_arg => undef, writer => '_set_pattern_regex');
has methods_regex => (is => 'rw', isa => 'RegexpRef', init_arg => undef, writer => '_set_methods_regex');

around BUILDARGS => sub {
    my $sub   = shift;
    my $class = shift;
    my $args  = $class->$sub(@_);

    my $pattern = $args->{pattern} || "/";
    $pattern !~ m!^/! and $pattern = "/$pattern";
    $pattern =~ s!(.+)/$!$1!;
    $args->{pattern} = $pattern;

    if ($args->{methods}) {
        $args->{methods} = [ grep /^GET|HEAD|PUT|POST|DELETE$/, map uc, @{$args->{methods}} ];
    }

    $args;
};

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

    $self->_set_pattern_regex(qr/^$pattern$/);

    if ($self->has_methods) {
        my $methods = join '|', $self->method_list;
        $self->_set_methods_regex(qr/^(?:$methods)$/);
    }
}

sub anonymous {
    !! ref $_[0]->handler;
}

sub named {
    ! ref $_[0]->handler;
}

sub name {
    my $handler = $_[0]->handler; ref $handler ? 'CODEREF' : $handler;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

