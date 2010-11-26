package Template::Plugin::Catmandu::Builder;

use 5.010;
use strict;
use warnings;
use base 'Template::Plugin';

sub new {
    my ($class, $context, @vars) = @_;
    my $opts = ref $vars[-1] eq 'HASH' ? pop @vars : {};
    my $schema = $opts->{schema};
    my $var = join '.', @vars;
    bless {
        context => $context,
        var => $var,
        schema => $schema,
        stack => [],
    }, $class;
}

sub _throw {
    my ($self, $error) = @_;
    $self->{context}->throw($error);
}

sub builder {
    my ($self, @vars) = @_;
    my $class = ref $self;
    $class->new($self->{context},
                $self->{var},
                @vars);
}

sub var {
    my ($self, @vars) = @_;
    my $var = $self->{var};
    if (@vars and $var) {
        join '.', $var, @vars;
    } elsif (@vars) {
        join '.', @vars;
    } else {
        $var;
    }
}

sub get {
    my ($self, @vars) = @_;
    my @key = map { ($_, 0) } split(/\./, $self->var(@vars));
    $self->{context}->stash->get(\@key);
}

sub id {
    my ($self, @vars) = @_;
    my $var = $self->var(@vars);
    $var =~ s/([a-z0-9])([A-Z)])/$1_\l$2/g;
    $var =~ s/\./-/g;
    $var;
}

sub form {
    my ($self, $attr) = @_;
    $attr ||= {};
    $attr->{'method'} //= "post";
    $attr->{'action'} //= "";
    $attr->{'accept-charset'} //= "utf-8";
    $attr = $self->_attributes($attr);
    push @{$self->{stack}}, 'form';
    "<form$attr>";
}

sub fieldset {
    my ($self, @args) = @_;
    my $attr   = $self->_attributes(ref $args[-1] eq 'HASH' ? pop @args : {});
    my $legend = defined $args[0] ? $self->tag('legend', $args[0]) : "";
    push @{$self->{stack}}, 'fieldset';
    "<fieldset$attr>$legend";
}

sub end {
    my ($self) = @_;
    my $tag = pop @{$self->{stack}};
    "</$tag>";
}

sub legend {
    my ($self, @args) = @_;
    $self->tag('legend', @args);
}

sub build {
    my ($self, @vars) = @_;
    my $attr = ref $vars[-1] eq 'HASH' ? pop @vars : {};

    if ($self->{schema} and my $property = $self->{schema}{properties}{$vars[0]}) {
        given ($property->{format}) {
            when ('email')     { return $self->input('email',    @vars, $attr) }
            when ('uri')       { return $self->input('url',      @vars, $attr) }
            when ('date')      { return $self->input('date',     @vars, $attr) }
            when ('time')      { return $self->input('time',     @vars, $attr) }
            when ('date-time') { return $self->input('datetime', @vars, $attr) }
        }
    }

    $self->input('text', @vars, $attr);
}

sub input {
    my ($self, $type, @vars) = @_;
    my $attr = ref $vars[-1] eq 'HASH' ? pop @vars : {};
    @vars or $self->_throw("Name can't be empty");
    $attr->{type} = $type;
    $attr->{name} = $self->var(@vars);
    $attr->{value} = $self->get(@vars);
    $attr->{id} //= $self->id(@vars);

    if ($self->{schema} and my $prop = $self->{schema}{properties}{$vars[0]}) {
        $attr->{required} = "required" if $prop->{required};

        if (my $val = $prop->{title}) { $attr->{title} = $val }

        if ($type =~ /number/) {
            if (my $val = $prop->{maximum}) { $attr->{max} = $val }
            if (my $val = $prop->{minimum}) { $attr->{min} = $val }
        }
        if ($type =~ /text/) {
            if (my $val = $prop->{maxLength}) { $attr->{maxlength} = $val }
            if (my $val = $prop->{pattern})   { $attr->{pattern}   = $val }
        }
    }

    $self->tag('input', $attr);
}

sub hidden   { my ($self, @vars) = @_; $self->input('hidden', @vars); }
sub text     { my ($self, @vars) = @_; $self->input('text', @vars); }
sub password { my ($self, @vars) = @_; $self->input('password', @vars); }
sub search   { my ($self, @vars) = @_; $self->input('search', @vars); }
sub url      { my ($self, @vars) = @_; $self->input('url', @vars); }
sub email    { my ($self, @vars) = @_; $self->input('email', @vars); }
sub number   { my ($self, @vars) = @_; $self->input('number', @vars); }
sub date     { my ($self, @vars) = @_; $self->input('date', @vars); }
sub time     { my ($self, @vars) = @_; $self->input('time', @vars); }
sub datetime { my ($self, @vars) = @_; $self->input('datetime', @vars); }

sub text_area {
    my ($self, @vars) = @_;
    my $attr = ref $vars[-1] eq 'HASH' ? pop @vars : {};
    @vars or $self->_throw("Name can't be empty");
    $attr->{name} = $self->var(@vars);
    $attr->{id} //= $self->id(@vars);
    $self->tag('textarea', $self->get(@vars), $attr);
}

sub select_options {
    my ($self, @vars) = @_;
    my $opts = pop @vars;
    ref $opts eq 'ARRAY' or $self->_throw("Option values missing");
    @vars or $self->_throw("Name can't be empty");
    my $value = $self->get(@vars);
    join '', map {
        my $pair = ref $_ eq 'ARRAY' ? $_ : [$_, $_];
        my $attr = {value => $pair->[0]};
        $attr->{selected} = "selected" if $value eq $pair->[0];
        $self->tag('option', $pair->[1] // $pair->[0], $attr);
    } @$opts;
}

sub select {
    my ($self, @vars) = @_;
    my $attr = ref $vars[-1] eq 'HASH' ? pop @vars : {};
    my $opts = pop @vars;
    @vars or $self->_throw("Name can't be empty");
    $attr->{name} = $self->var(@vars);
    $attr->{id} //= $self->id(@vars);
    $self->tag('select', $self->select_options(@vars, $opts), $attr);
}

sub label {
    my ($self, @args) = @_;
    $self->tag('label', @args);
}

sub submit {
    my ($self, @args) = @_;
    my $attr = ref $args[-1] eq 'HASH' ? pop @args : {};
    $attr->{value} = $args[0] // "Submit";
    $attr->{type} = "submit";
    $self->tag('input', $attr);
}

sub tag {
    my ($self, $tag, @args) = @_;
    my $attr = ref $args[-1] eq 'HASH' ? pop @args : {};
    $attr = $self->_attributes($attr);
    if (defined $args[0]) {
        "<$tag$attr>$args[0]</$tag>";
    } else {
        "<$tag$attr>";
    }
}

sub _attributes {
    my ($self, $attr) = @_;
    join "", map qq( $_="$attr->{$_}"), keys %$attr;
}

__PACKAGE__;

