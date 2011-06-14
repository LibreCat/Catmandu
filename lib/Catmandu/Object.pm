package Catmandu::Object::Base;
use Catmandu::Sane;

sub new {
    my $self = shift;
    $self = bless {}, ref($self) || $self;
    $self->_build($self->_build_args(@_));
    $self;
}

sub _build_args {
    shift;
    ref $_[0] ? $_[0] : {@_};
}

sub _build {
    my ($self, $args) = @_;
    $self->{$_} = $args->{$_} for keys %$args;
    $self;
}

package Catmandu::Object;
use Catmandu::Sane;
use Catmandu::Util qw(add_parent add_sub);

sub base { 'Catmandu::Object::Base' }

sub _field_registry {
    state $field_registry = {};
}

sub fields {
    my ($self, $pkg) = @_;
    my $isa = mro::get_linear_isa(ref($pkg) || $pkg);
    my $all = [];
    for my $pkg (@$isa) {
        continue unless $pkg->isa($self->base);
        if (my $fields = $self->_field_registry->{$pkg}) {
            push @$all, keys %$fields;
        }
    }
    $all;
}

sub import {
    my ($self, %fields) = @_;

    my $pkg = caller;

    add_parent($pkg, $self->base) unless $pkg->isa($self->base);

    for my $key (keys %fields) {
        my $val = $fields{$key};
        my $opt;

        if (ref $val) {
            $opt = $val;
            $opt->{reader} //= 1;
        } else {
            $opt = {};
            given ($val) {
                when ('r')  { $opt->{reader} = 1 }
                when ('w')  { $opt->{writer} = 1 }
                when ('rw') { $opt->{reader} = $opt->{writer} = 1 }
            }
        }

        $opt->{reader} = $key       if $opt->{reader} && $opt->{reader} == 1;
        $opt->{writer} = "set_$key" if $opt->{writer} && $opt->{writer} == 1;

        $self->_field_registry->{$pkg}{$key} = $opt;

        if ($opt->{reader}) {
            my $sub = $opt->{default};

            if (ref $sub) {
                add_sub($pkg, $opt->{reader} => sub { $_[0]->{$key} //= $sub->($_[0]) });
            } elsif ($sub) {
                add_sub($pkg, $opt->{reader} => sub { $_[0]->{$key} //= $_[0]->$sub() });
            } else {
                add_sub($pkg, $opt->{reader} => sub { $_[0]->{$key} });
            }
        }

        if ($opt->{writer}) {
            add_sub($pkg, $opt->{writer} => sub { $_[0]->{$key} = $_[1] });
        }
    }
}

1;
