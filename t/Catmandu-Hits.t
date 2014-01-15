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

my $h2 = Catmandu::Hits->new(start => 20, limit => 5, total => 632, hits => $data);

foreach (qw(next_page last_page page previous_page pages_in_spread)) {
	$h->{pager}->{$_} = $h->$_;
	$h2->{pager}->{$_} = $h2->$_;
}

my $pager = {
	previous_page => undef,
	next_page => '2',
	last_page => '10',
	page => '1',
	pages_in_spread => [1, 2, 3, 4, 0, 9, 10],
	};
$pager->{pages_in_spread}->[4] = undef;

is_deeply ($h->{pager}, $pager, "pagination ok");

my $pager2 = {
	previous_page => '4',
	next_page => '6',
	last_page => '127',
	page => '5',
	pages_in_spread => [1, 0, 4, 5, 6, 7, 0, 127],
};
$pager2->{pages_in_spread}->[1] = undef;
$pager2->{pages_in_spread}->[6] = undef;

is_deeply ($h2->{pager}, $pager2, "another pagination ok");

done_testing 17;

