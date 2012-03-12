#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use File::Spec::Functions qw(catdir splitdir abs2rel);
use Cwd qw(realpath);
use File::Find;

my $base_dir  = realpath(catdir($FindBin::Bin, '..'));
my $lib_dir   = catdir($base_dir, 'lib');
my $tests_dir = catdir($base_dir, 't');

my $test_tmpl = <<PL;
#!/usr/bin/env perl

use strict;
use warnings;
use Catmandu::ConfigData;
use Test::More;
use Test::Exception;

my \$pkg;
BEGIN {
    #unless (Catmandu::ConfigData->feature('')) {
    #    plan skip_all => 'feature disabled';
    #}
    \$pkg = '%s';
    use_ok \$pkg;
}
require_ok \$pkg;

done_testing 2;

PL

my $gen_test = sub {
    return unless /^\w+\.pm$/;
    my $pkg = abs2rel($File::Find::name, $lib_dir);
    $pkg =~ s/\.pm$//;
    my $test = catdir($tests_dir, join('-', splitdir($pkg)).'.t');
    return if -f $test;
    $pkg = join('::', splitdir($pkg));
    open T, ">$test";
    printf T $test_tmpl, $pkg;
    close T;
};

find($gen_test, $lib_dir);

