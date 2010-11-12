package Catmandu::Cmd;

use strict;
use warnings;
use Path::Class;
use Plack::Util;

sub run {
    if ($ENV{CATMANDU_HOME}) {
        $ENV{CATMANDU_HOME} = dir($ENV{CATMANDU_HOME})->absolute->resolve->stringify;
    } else {
        $ENV{CATMANDU_HOME} = dir->absolute->stringify;
    }

    $ENV{CATMANDU_ENV} ||= 'development';

    my $pkg = join '::', __PACKAGE__, ucfirst $ARGV[0];
    Plack::Util::load_class($pkg);
    $pkg->new_with_options()->run;
}

__PACKAGE__;

