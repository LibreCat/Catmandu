package Catmandu::Fix::Loader;

use Catmandu::Sane;
use Catmandu::Util qw(:is load_package);
use File::Slurp;

my $fixes;

sub load_fixes {
    $fixes = [];
    for my $fix (@_) {
        if (is_able($fix, 'fix')) {
            push @$fixes, $fix;
        } elsif (is_string($fix)) {
            $fix = read_file($fix) if -r $fix;
            eval "package Catmandu::Fix::Sandbox;$fix;1" or confess $@;
        }
    }
    $fixes;
}

sub add_fix {
    my ($fix, @args) = @_;
    push @$fixes, load_package($fix, 'Catmandu::Fix')->new(@args);
}

package Catmandu::Fix::Sandbox;

use strict;
use warnings;

sub AUTOLOAD {
    my ($fix) = our $AUTOLOAD =~ /::(\w+)$/;

    my $sub = sub { Catmandu::Fix::Loader::add_fix($fix, @_); return };

    { no strict 'refs'; *$AUTOLOAD = $sub };

    $sub->(@_);
}

sub DESTROY {}

package Catmandu::Fix;

use Catmandu::Sane;
use Catmandu::Util qw(is_able);
use Catmandu::Iterator;
use Moo;

has fixes => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    $orig->($class, fixes => Catmandu::Fix::Loader::load_fixes(@args));
};

sub fix {
    my ($self, $data) = @_;

    if (is_able($data, 'generator') && is_able($data, 'map')) {
        return $data->map(sub {
            $self->fix($_[0]);
        });
    }

    if (ref $data eq 'CODE') {
        return sub {
            $self->fix($data->() || return);
        };
    }

    if (ref $data eq 'HASH') {
        for my $fix (@{$self->fixes}) {
            $data = $fix->fix($data);
        }
        return $data;
    }

    return;
}

1;
