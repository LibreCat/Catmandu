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

my $data = [1,2,3];
my $h = Catmandu::Hits->new(start => 0, limit => 10, total => 100, hits => $data);
can_ok $h, 'start';
can_ok $h, 'limit';
can_ok $h, 'total';
can_ok $h, 'hits';
can_ok $h, 'size';
throws_ok { Catmandu::Hits->new(limit => 10, total => 100, hits => $data) } qr/missing required arguments: start/i;
throws_ok { Catmandu::Hits->new(start => 0, total => 100, hits => $data) } qr/missing required arguments: limit/i;
throws_ok { Catmandu::Hits->new(start => 0, limit => 10, hits => $data) } qr/missing required arguments: total/i;
throws_ok { Catmandu::Hits->new(start => 0, limit => 10, total => 100) } qr/missing required arguments: hits/i;
ok $h->does('Catmandu::Iterable');
ok $h->does('Catmandu::Paged');

is_deeply $h->hits, $data;
is $h->size, 3;

done_testing 15;
