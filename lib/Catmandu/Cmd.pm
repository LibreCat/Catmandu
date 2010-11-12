package Catmandu::Cmd;

use 5.010;
use Path::Class;

sub run {
    my $argv = [];
    my $home = $ENV{CATMANDU_HOME};
    my $env  = $ENV{CATMANDU_ENV};
    my $cmd  = shift;

    while (my $arg = shift) {
        given ($arg) {
            when (/-H|--home/) { $home = shift }
            when (/-E|--env/)  { $env  = shift }
            default {
                push @$argv, $arg;
            }
        }
    }

    if ($home) {
        $ENV{CATMANDU_HOME} = dir($home)->absolute->resolve->stringify;
    } else {
        $ENV{CATMANDU_HOME} = dir->absolute->stringify;
    }

    $ENV{CATMANDU_ENV} = $env || 'development';

    my @perl = (
        "use Catmandu",
        "use lib Catmandu->lib",
        "use all of => 'Catmandu::Cmd'");
    foreach (@perl) {
        eval;
        $@ and confess $@;
    }

    my %packages = do {
        my $namespace = __PACKAGE__;
        no strict 'refs';
        my @basenames = map { s/::$//; $_ } grep { /::$/ } keys %{"${namespace}::"};
        map { (lc $_, "${namespace}::$_") } @basenames;
    };

    if (my $pkg = $packages{$cmd}) {
        return $pkg->new_with_options(argv => $argv)->run;
    }

    

    exit 0 if grep /$cmd/, qw(-? --help --usage);
    exit 1;
}

__PACKAGE__;

