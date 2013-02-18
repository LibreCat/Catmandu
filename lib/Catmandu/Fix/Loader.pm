package Catmandu::Fix::Loader::Env;

use strict;
use warnings FATAL => 'all';

sub AUTOLOAD {
    my ($fix) = our $AUTOLOAD =~ /::(\w+)$/;

    my $sub = sub { Catmandu::Fix::Loader::_add_fix($fix, @_); return };

    { no strict 'refs'; *$AUTOLOAD = $sub };

    $sub->(@_);
}

sub DESTROY {}

package Catmandu::Fix::Loader;

use Catmandu::Sane;
use Catmandu::Util qw(:is require_package read_file);

my @fixes;
my @stack;

sub load_fixes {
    @fixes = ();
    @stack = ();
    for my $fix (@{$_[0]}) {
        if (is_able($fix, 'fix')) {
            push @fixes, $fix;
        } elsif (is_string($fix)) {
            if (-r $fix) {
                $fix = read_file($fix);
            }
            eval "package Catmandu::Fix::Loader::Env;$fix;1" or confess $@;
        }
    }
    confess "if without end" if @stack;
    [@fixes];
}

sub _add_fix {
    my ($fix, @args) = @_;

    if ($fix eq 'end') {
        $fix = pop @stack || confess "end without if";
        if (@stack) {
            push @{$stack[-1]->fixes}, $fix;
        } else {
            push @fixes, $fix;
        }
    }
    elsif ($fix =~ s/^if_//) {
        $fix = require_package($fix, 'Catmandu::Fix::Condition')->new(@args);
        push @stack, $fix;
    }
    elsif ($fix =~ s/^unless_//) {
        $fix = require_package($fix, 'Catmandu::Fix::Condition')->new(@args);
        $fix->invert(1);
        push @stack, $fix;
    }
    elsif ($fix =~ /^[a-z]/) {
        $fix = require_package($fix, 'Catmandu::Fix')->new(@args);
        if (@stack) {
            push @{$stack[-1]->fixes}, $fix;
        } else {
            push @fixes, $fix;
        }
    }
    else {
        confess "invalid fix name";
    }
}

1;