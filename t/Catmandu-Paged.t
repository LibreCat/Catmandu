#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Paged';
    use_ok $pkg;
}
require_ok $pkg;

{
	package T::PagedWithoutStart;
	use Moo;
	sub limit {}
	sub total {}

	package T::PagedWithoutLimit;
	use Moo;
	sub start {}
	sub total {}

	package T::PagedWithoutTotal;
	use Moo;
	sub start {}
	sub limit {}

	package T::Paged;
	use Moo;
	with $pkg;

	sub start { return 27; }
	sub limit { return 20; }
	sub total { return 32432; }

	package T2::Paged;
	use Moo;
	with $pkg;

	sub start { return 1; }
	sub limit { return 10; }
	sub total { return 127; }

	package T3::Paged;
	use Moo;
	with $pkg;

	sub start { return 0; }
	sub limit { return 10; }
	sub total { return 33; }
}

throws_ok { Role::Tiny->apply_role_to_package('T::PagedWithoutStart', $pkg) } qr/missing start/;
throws_ok { Role::Tiny->apply_role_to_package('T::PagedWithoutLimit', $pkg) } qr/missing limit/;
throws_ok { Role::Tiny->apply_role_to_package('T::PagedWithoutTotal', $pkg) } qr/missing total/;

my $p = T::Paged->new;
can_ok $p, $_ for qw/first_page page previous_page next_page first_on_page last last_page pages_in_spread/;

is $p->first_page, 1, "first page ok";
is $p->page, 2, "Page ok";
is $p->previous_page, 1 ,"previous ok";
is $p->next_page, 3, "next ok";
is $p->page_size, 20, "page size ok";
is $p->first_on_page, 21, "first on page ok";
is $p->last, 40, "last on page ok";
is $p->last_page, 1622, "last page ok";
my @arr = (1,2,3,4,5,undef,1622);
is_deeply \@{$p->pages_in_spread}, \@arr, "spread ok";

my $p2 = T2::Paged->new;
is $p2->first_page, 1, "first page ok";
is $p2->page, 1, "Page ok";
is $p2->previous_page, undef, "previous ok";
is $p2->next_page, 2, "next ok";
is $p2->page_size, 10, "page size ok";
is $p2->first_on_page, 1, "first on page ok";
is $p2->last, 10, "last on page ok";
is $p2->last_page, 13, "last page ok";
my @arr2 = (1,2,3,4,undef,12,13);
is_deeply \@{$p2->pages_in_spread}, \@arr2, "spread ok";

my $p3 = T3::Paged->new;
is $p3->first_page, 1, "first page ok";
is $p3->page, 1, "Page ok";
is $p3->previous_page, undef, "previous ok";
is $p3->next_page, 2, "next ok";
is $p3->page_size, 10, "page size ok";
is $p3->first_on_page, 1, "first on page ok";
is $p3->last, 10, "last on page ok";
is $p3->last_page, 4, "last page ok";
my @arr3 = (1,2,3,4);

is_deeply \@{$p3->pages_in_spread}, \@arr3, "spread ok";

done_testing 40;
