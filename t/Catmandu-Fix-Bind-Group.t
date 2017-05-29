#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Util qw(:is);

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Bind::Group';
    use_ok $pkg;
}
require_ok $pkg;

done_testing 2;
