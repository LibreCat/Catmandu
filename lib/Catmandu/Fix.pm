package Catmandu::Fix::Loader;

use Catmandu::Sane;
use Catmandu::Util qw(:is load_package);
use File::Slurp;

my $fixes;

sub load_fixes {
    $fixes = [];
    for my $fix (@{$_[0]}) {
        if (is_able($fix, 'fix')) {
            push @$fixes, $fix;
        } elsif (is_string($fix)) {
            if (-r $fix) {
                $fix = read_file($fix);
            }
            eval "package Catmandu::Fix::Loader::Env;$fix;1" or confess $@;
        }
    }
    $fixes;
}

sub add_fix {
    my ($fix, @args) = @_;
    $fix = load_package($fix, 'Catmandu::Fix');
    push @$fixes, $fix->new(@args);
}

package Catmandu::Fix::Loader::Env;

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
use Catmandu::Util qw(:is :check);
use Catmandu::Iterator;
use Moo;

has fixes => (
    is => 'ro',
    required => 1,
    coerce => sub {
        Catmandu::Fix::Loader::load_fixes(check_array_ref($_[0]));
    },
);

sub fix {
    my ($self, $data) = @_;

    my $fixes = $self->fixes;

    if (is_hash_ref($data)) {
        for my $fix (@$fixes) {
            $data = $fix->fix($data);
        }
        return $data;
    }

    if (is_invocant($data)) {
        return $data->map(sub {
            my $d = $_[0];
            $d = $_->fix($d) for @$fixes;
            $d;
        });
    }

    if (is_code_ref($data)) {
        return sub {
            my $d = $data->();
            $d || return;
            $d = $_->fix($d) for @$fixes;
            $d;
        };
    }

    return;
}

1;
