package Catmandu::Class;
use Catmandu::Sane;
use Catmandu::Util;

sub base { 'Catmandu::Class::Base' }

sub import {
    my ($self, @fields) = @_;

    my $caller = caller;

    Catmandu::Sane->import(level => 2);

    unless ($caller->isa($self->base)) {
        Catmandu::Util::add_parent($caller, $self->base);
    }

    for my $field (@fields) {
        Catmandu::Util::add_subroutine($caller, $field => sub { $_[0]->{$field} });
    }
}

package Catmandu::Class::Base;
use Catmandu::Sane;

sub new {
    my $self = shift;
    $self = bless {}, ref $self || $self;
    $self->build($self->build_args(@_));
    $self;
}

sub build_args {
    shift;
    ref $_[0] eq 'HASH' ? $_[0] : {@_};
}

sub build {
    my ($self, $args) = @_;
    foreach (keys %$args) {
        $self->{$_} = $args->{$_};
    }
    $self;
}

1;
