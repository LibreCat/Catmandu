#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Hits';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [(1 .. 100)];
my $h    = Catmandu::Hits->new(start => 0, limit => 10, total => 100,
    hits => $data);
can_ok $h, 'start';
can_ok $h, 'limit';
can_ok $h, 'total';
can_ok $h, 'maximum_offset';
can_ok $h, 'hits';
can_ok $h, 'size';
throws_ok {Catmandu::Hits->new(limit => 10, total => 100, hits => $data)}
qr/missing required arguments: start/i;
throws_ok {Catmandu::Hits->new(start => 0, total => 100, hits => $data)}
qr/missing required arguments: limit/i;
throws_ok {Catmandu::Hits->new(start => 0, limit => 10, hits => $data)}
qr/missing required arguments: total/i;
throws_ok {Catmandu::Hits->new(start => 0, limit => 10, total => 100)}
qr/missing required arguments: hits/i;
ok $h->does('Catmandu::Iterable'), 'is an Iterable';
ok $h->does('Catmandu::Paged'),    'is a Paged';

is_deeply $h->hits, $data, 'test content';

ok $h->more, 'test mode';
is $h->limit, 10,  'test limit';
is $h->size,  100, 'test size';
is $h->start, 0,   'test start';
is $h->first, 1,   'test first';

my $sum = 0;
$h->each(sub {$sum += shift});
is $sum , 5050, 'test each';

is_deeply $h->to_array, [(1 .. 100)], 'test to_array';

is $h->generator->(), 1, 'test generator';

done_testing;
