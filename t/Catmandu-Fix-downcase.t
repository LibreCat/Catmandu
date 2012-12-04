#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::downcase';
    use_ok $pkg;
}
require_ok $pkg;

my ($fixer, $fixed_hash);

$fixer = Catmandu::Fix->new(fixes => ['add_field("job","Author")', 'downcase("job")']);
$fixed_hash = $fixer->fix({});
is_deeply $fixed_hash, { 'job' => 'author' }, "downcasing works";

$fixer = Catmandu::Fix->new(fixes => ['add_field("job","Author")', 'downcase("occupation")']);
$fixed_hash = $fixer->fix({});
is_deeply $fixed_hash, { 'job' => 'Author' }, "no changes if key not found";

done_testing 4;

