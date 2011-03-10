package Catmandu::Route;
use Catmandu::Class qw(
    pattern
    methods
    handler
    components
    parameters
    defaults
    pattern_regex
    methods_regex
);

sub build {
    my ($self, $args) = @_;

    $self->{pattern}       = $self->_normalize_pattern($args->{pattern} || "/");
    $self->{methods}       = $self->_normalize_methods($args->{methods} || []);
    $self->{handler}       = $args->{handler};
    $self->{components}    = [];
    $self->{parameters}    = [];
    $self->{defaults}      = $args->{defaults} || {};

    $self->{pattern_regex} = $self->_compile_pattern_regex($self->pattern);
    $self->{methods_regex} = $self->_compile_methods_regex($self->methods);
}

sub _normalize_pattern {
    my ($self, $pattern) = @_; # add leading and remove trailing slashes
    $pattern = "/$pattern" unless $pattern =~ m!^/!;
    $pattern =~ s!(.+)/+$!$1!;
    $pattern;
}

sub _normalize_methods {
    my ($self, $methods) = @_;
    [ grep /^GET|HEAD|PUT|POST|DELETE$/, map uc, @$methods ];
}

sub _compile_pattern_regex {
    my ($self, $pattern) = @_;

    $pattern =~ s!
        \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
        :([A-Za-z0-9_]+)              | # /blog/:year
        (\*)                          | # /blog/*/*
        ([^{:*]+)
    !
        if ($1) {
            my ($name, $regex) = split /:/, $1, 2;
            push @{$self->components}, { name => $name, regex => $regex };
            push @{$self->parameters}, $name;
            $regex ? "($regex)" : "([^/]+)";
        }
        elsif ($2) {
            push @{$self->components}, { name => $2 };
            push @{$self->parameters}, $2;
            "([^/]+)";
        }
        elsif ($3) {
            push @{$self->components}, { name => 'splat' };
            push @{$self->parameters}, 'splat';
            "(.+)";
        }
        else {
            push @{$self->components}, $4;
            quotemeta($4);
        }
    !gex;

    qr/^$pattern$/;
}

sub _compile_methods_regex {
    my ($self, $methods) = @_;
    return unless scalar @$methods;
    $methods = join '|', @$methods;
    qr/^(?:$methods)$/;
}

sub named {
    ! ref $_[0]->handler;
}

sub anonymous {
    ! ref $_[0]->named;
}

sub name {
    ref $_[0]->handler ? 'CODE' : $_[0]->handler;
}

1;
