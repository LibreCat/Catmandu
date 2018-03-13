#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::error';
    use_ok $pkg;
}

throws_ok {$pkg->new('!!!ERROR!!!')->fix({})} qr/!!!ERROR!!!/,
    'dies with an error message';

throws_ok {$pkg->new('$.error')->fix({error => '!!!ERROR!!!'})}
qr/!!!ERROR!!!/, 'dies with an error message';

throws_ok {
    $pkg->new('$.errors.*')->fix({errors => ['!!!ERROR!!!', '!!!PANIC!!!']})
}
qr/!!!ERROR!!!/, 'dies with an error message';

lives_ok {
    $pkg->new('$.errors.*')->fix({errors => []})
}
'lives if there are no error messages';

done_testing;
