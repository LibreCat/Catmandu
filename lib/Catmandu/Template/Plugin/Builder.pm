package Catmandu::Template::Plugin::Builder;

use 5.010;
use strict;
use warnings;
use base 'Template::Plugin';

sub new {
    my ($class, $context, @vars) = @_;
    my $var = join '.', @vars;
    bless {
        context => $context,
        stack => [],
        var => $var,
    }, $class;
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

sub form {
    my ($self, $attr) = @_;
    $attr ||= {};
    $attr->{'method'} //= "post";
    $attr->{'action'} //= "";
    $attr->{'accept-charset'} //= "utf-8";
    $attr = $self->_attributes($attr);
    my $stack = $self->{stack};
    grep /form/, @$stack and $self->_error("Can't embed form tag");
    push @$stack, 'form';
    "<form$attr>";
}

sub end {
    my ($self) = @_;
    my $stack = $self->{stack};
    my $tag = pop @$stack; 
    $tag or return;
    "</$tag>";
}

sub _field {
    my ($self, $type, @vars) = @_;
    my $attr = ref $vars[-1] eq 'HASH' ? pop @vars : {};
    @vars or $self->_error("Name can't be empty");
    $attr->{type}  = $type;
    $attr->{name}  = $self->var(@vars);
    $attr->{value} = $self->get(@vars);
    $self->tag('input', $attr);
}

sub hidden {
    my ($self, @vars) = @_; $self->_field('hidden', @vars);
}

sub password {
    my ($self, @vars) = @_; $self->_field('password', @vars);
}

sub text {
    my ($self, @vars) = @_; $self->_field('text', @vars);
}

sub text_area {
    my ($self, @vars) = @_;
    my $attr = ref $vars[-1] eq 'HASH' ? pop @vars : {};
    @vars or $self->_error("Name can't be empty");
    $attr->{name} = $self->var(@vars);
    $self->tag('textarea', $self->get(@vars), $attr);
}

sub select_options {
    my ($self, @vars) = @_;
    my $opts = pop @vars;
    ref $opts eq 'ARRAY' or $self->_error("Option values missing");
    @vars or $self->_error("Name can't be empty");
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
    @vars or $self->_error("Name can't be empty");
    $attr->{name} = $self->var(@vars);
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
    my $attr = $_[1]; join "", map qq( $_="$attr->{$_}"), keys %$attr;
}

sub _error {
    $_[0]->{context}->throw($_[1]);
}

__PACKAGE__;

