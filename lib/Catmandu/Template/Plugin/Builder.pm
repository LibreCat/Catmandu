package Catmandu::Template::Plugin::Builder;

use 5.010;
use strict;
use warnings;
use base 'Template::Plugin';

sub new {
    my ($class, $context, $obj) = @_;
    $obj ||= {};
    bless {
        context => $context,
        obj => $obj,
    }, $class;
}

sub hidden_field {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self, $name, $value) = @_;
    $attrs->{type} = "hidden";
    $attrs->{value} //= $value;
    $attrs->{name} //= $name;
    $self->tag('input', $attrs);
}

sub text_field {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self, $name, $value) = @_;
    $attrs->{type} = "text";
    $attrs->{value} //= $value;
    $attrs->{name} //= $name;
    $self->tag('input', $attrs);
}

sub text_area {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self, $name, $value) = @_;
    $attrs->{name} //= $name;
    $value //= "";
    $self->tag('textarea', $attrs, $value);
}

sub label {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self, $name, $value) = @_;
    $value //= "";
    $self->tag('label', $attrs, $value);
}

sub tag {
    my ($self, $tag, $attrs, $inner) = @_;
    $attrs = join "", map qq( $_="$attrs->{$_}"), keys %$attrs;
    if (defined $inner) {
        "<$tag$attrs>$inner</$tag>";
    } else {
        "<$tag$attrs>";
    }
}

__PACKAGE__;

