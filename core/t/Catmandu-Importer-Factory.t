#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

BEGIN { use_ok('Catmandu::Importer::Factory'); }
require_ok('Catmandu::Importer::Factory');

## Write your tests
# is($got,$expected,$test_name);
# isnt($got,$expected,$test_name);
# like($got, qr/regex/,$test_name);
# unlike($got, qr/regex/,$test_name);
# is_deeply($got_hash,$expected_hash,$test_name);
# can_ok($module,@methods);
# throws_ok { [CODE] } qr/regex/ , $test_name;
