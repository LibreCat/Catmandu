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
    $_[0]->{var};
}

sub get {
    my ($self, @vars) = @_;
    my $var = join '.', @vars;
    my @key = map { ($_, 0) } ( split(/\./, $self->var), split(/\./, $var) );
    $self->{context}->stash->get(\@key);
}

sub form {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self) = @_;

    if ($self->{close_form_tag}) {
        $self->{close_form_tag} = 0;
        return "</form>";
    } else {
        $attrs->{action} ||= "";
        $attrs->{method} ||= "post";
        $attrs = $self->_join_attrs($attrs);
        $self->{close_form_tag} = 1;
        "<form$attrs>";
    }
}

sub hidden_field {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self, @name) = @_;
    $attrs->{type} = "hidden";
    $attrs->{name} //= join('.', @name) or
        $self->{context}->throw("name missing");
    $attrs->{value} //= $self->get($attrs->{name});
    $attrs->{name} = join '.', $self->var, $attrs->{name} if $self->var;
    $self->tag('input', $attrs);
}

sub password_field {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self, @name) = @_;
    $attrs->{type} = "password";
    $attrs->{name} //= join('.', @name) or
        $self->{context}->throw("name missing");
    $attrs->{value} //= $self->get($attrs->{name});
    $attrs->{name} = join '.', $self->var, $attrs->{name} if $self->var;
    $self->tag('input', $attrs);
}

sub text_field {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self, @name) = @_;
    $attrs->{type} = "text";
    $attrs->{name} //= join('.', @name) or
        $self->{context}->throw("name missing");
    $attrs->{value} //= $self->get($attrs->{name});
    $attrs->{name} = join '.', $self->var, $attrs->{name} if $self->var;
    $label . $self->tag('input', $attrs);
}

sub text_area {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self, @name) = @_;
    $attrs->{name} //= join('.', @name) or
        $self->{context}->throw("name missing");
    my $value = $self->get($attrs->{name}) // "";
    $attrs->{name} = join '.', $self->var, $attrs->{name} if $self->var;
    $self->tag('textarea', $attrs, $value);
}

sub select {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self, @name) = @_;
    $attrs->{name} //= join('.', @name) or
        $self->{context}->throw("name missing");
    my $value = $self->get($attrs->{name});
    $attrs->{name} = join '.', $self->var, $attrs->{name} if $self->var;
    my $options = delete $attrs->{options} or 
        $self->{context}->throw("options missing");
    $options = join "", map {
        my $o = $_;
        my $v;
        my $d;
        if (ref $o eq 'ARRAY') {
            $v = $o->[0];
            $d = $o->[1] // $o->[0];
        } else {
            $v = $d = $o;
        }
        my $a = {value => $v};
        $a->{selected} = "selected" if $v eq $value;
        $self->tag('option', $a, $d)
    } @$options;
    $self->tag('select', $attrs, $options);
}

sub label {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self, @name) = @_;
    $attrs->{for} //= join('.', @name) or
        $self->{context}->throw("name missing");
    $attrs->{for} = join '.', $self->var, $attrs->{for} if $self->var;
    $attrs->{for} =~ m/(\w+)$/;
    my $value = $1;
    $self->tag('label', $attrs, $value);
}

sub submit {
    my $attrs = ref $_[-1] eq 'HASH' ? pop @_ : {};
    my ($self, $value) = @_;
    $attrs->{type} = "submit";
    $attrs->{value} //= $value // "Submit";
    $self->tag('input', $attrs);
}

sub tag {
    my ($self, $tag, $attrs, $inside) = @_;
    $attrs = $self->_join_attrs($attrs);
    if (defined $inside) {
        "<$tag$attrs>$inside</$tag>";
    } else {
        "<$tag$attrs>";
    }
}

sub _join_attrs {
    my ($self, $attrs) = @_;
    join "", map qq( $_="$attrs->{$_}"), keys %$attrs;
}

__PACKAGE__;

