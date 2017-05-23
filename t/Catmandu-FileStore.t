#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::FileStore';
    use_ok $pkg;
}

require_ok $pkg;

done_testing();
