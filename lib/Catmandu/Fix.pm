package Catmandu::Fix;

use namespace::autoclean;
use Moose;
use Clone ();

sub fix {
    my ($self, $obj) = @_;
    $self->apply_fix(Clone::clone($obj));
}

sub apply_fix {
    my ($self, $obj) = @_;
    inner;
    $obj;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Catmandu::Fix

=head1 DESCRIPTION

This base class for a series of object fixers only deep clones
the object given. Child classes augment C<fix> to build
a useful transformation.

=head1 SYNOPSIS

    package FooFix;
    use Moose;
    extends 'Catmandu::Fix';

    augment apply_fix => sub {
        my ($self, $obj) = @_;
        $obj->{foo} = 'bar';
        inner;
        $obj;
    }

    package main;

    my $obj = {};
    my $fixer = FooFix->new;
    my $cloned_obj = $fixer->fix($obj);
    $obj->{foo}; # => undef
    $cloned_obj->{foo}; # => 'bar'

=head1 METHODS

=head2 $c->fix($obj)

fixes and returns a cloned C<$obj>.

=head2 $c->apply_fix($obj)

fixes and returns C<$obj>.

