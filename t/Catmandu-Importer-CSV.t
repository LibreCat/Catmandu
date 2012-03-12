#!/usr/bin/env perl

use strict;
use warnings;
use Catmandu::ConfigData;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    unless (Catmandu::ConfigData->feature('import_csv')) {
        plan skip_all => 'feature disabled';
    }
    $pkg = 'Catmandu::Importer::CSV';
    use_ok $pkg;
}
require_ok $pkg;

done_testing 2;

