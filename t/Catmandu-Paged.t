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
    sub limit          { }
    sub total          { }
    sub maximum_offset { }

    package T::PagedWithoutLimit;
    use Moo;
    sub start          { }
    sub total          { }
    sub maximum_offset { }

    package T::PagedWithoutTotal;
    use Moo;
    sub start          { }
    sub limit          { }
    sub maximum_offset { }

    package T::PagedWithoutMaximumOffset;
    use Moo;
    sub start { }
    sub limit { }
    sub total { }

    package T::Paged;
    use Moo;
    with $pkg;

    sub start          {27;}
    sub limit          {20;}
    sub total          {32432;}
    sub maximum_offset { }

    package T2::Paged;
    use Moo;
    with $pkg;

    sub start          {1;}
    sub limit          {10;}
    sub total          {127;}
    sub maximum_offset { }

    package T3::Paged;
    use Moo;
    with $pkg;

    sub start          {0;}
    sub limit          {10;}
    sub total          {33;}
    sub maximum_offset { }

    package T4::Paged;
    use Moo;
    with $pkg;

    sub start          {0;}
    sub limit          {10;}
    sub total          {33;}
    sub maximum_offset {23;}

    package T5::Paged;
    use Moo;
    with $pkg;

    sub start          {10;}
    sub limit          {0;}
    sub total          {100;}
    sub maximum_offset { }
}

throws_ok {Role::Tiny->apply_role_to_package('T::PagedWithoutStart', $pkg)}
qr/missing start/;
throws_ok {Role::Tiny->apply_role_to_package('T::PagedWithoutLimit', $pkg)}
qr/missing limit/;
throws_ok {Role::Tiny->apply_role_to_package('T::PagedWithoutTotal', $pkg)}
qr/missing total/;
throws_ok {
    Role::Tiny->apply_role_to_package('T::PagedWithoutMaximumOffset', $pkg)
}
qr/missing maximum_offset/;

my $p = T::Paged->new;
can_ok $p, $_
    for
    qw/first_page page previous_page next_page first_on_page last_on_page last_page pages_in_spread/;

is $p->first_page,    1,    "first page ok";
is $p->page,          2,    "Page ok";
is $p->previous_page, 1,    "previous ok";
is $p->next_page,     3,    "next ok";
is $p->page_size,     20,   "page size ok";
is $p->first_on_page, 21,   "first on page ok";
is $p->last_on_page,  40,   "last on page ok";
is $p->last_page,     1622, "last page ok";
my $arr = [1, 2, 3, 4, 5, undef, 1622];
is_deeply $p->pages_in_spread, $arr, "spread ok";

my $p2 = T2::Paged->new;
is $p2->first_page,    1,     "first page ok";
is $p2->page,          1,     "page ok";
is $p2->previous_page, undef, "previous ok";
is $p2->next_page,     2,     "next ok";
is $p2->page_size,     10,    "page size ok";
is $p2->first_on_page, 1,     "first on page ok";
is $p2->last_on_page,  10,    "last on page ok";
is $p2->last_page,     13,    "last page ok";
my $arr2 = [1, 2, 3, 4, undef, 12, 13];
is_deeply $p2->pages_in_spread, $arr2, "spread ok";

my $p3 = T3::Paged->new;
is $p3->first_page,    1,     "first page ok";
is $p3->page,          1,     "page ok";
is $p3->previous_page, undef, "previous ok";
is $p3->next_page,     2,     "next ok";
is $p3->page_size,     10,    "page size ok";
is $p3->first_on_page, 1,     "first on page ok";
is $p3->last_on_page,  10,    "last on page ok";
is $p3->last_page,     4,     "last page ok";
my $arr3 = [1, 2, 3, 4];

is_deeply $p3->pages_in_spread, $arr3, "spread ok";

my $p4 = T4::Paged->new;
is $p4->total,         33,    "total ok";
is $p4->first_page,    1,     "first page ok";
is $p4->page,          1,     "page ok";
is $p4->previous_page, undef, "previous ok";
is $p4->next_page,     2,     "next ok";
is $p4->page_size,     10,    "page size ok";
is $p4->first_on_page, 1,     "first on page ok";
is $p4->last_on_page,  10,    "last on page ok";
is $p4->last_page,     3,     "last page ok";
my $arr4 = [1, 2, 3];

is_deeply $p4->pages_in_spread, $arr4, "spread ok";

my $p5 = T5::Paged->new;
lives_ok { $p5->page } "limit 0 gives no errors";
is $p5->first_page,    undef,     "limit 0 first page ok";
is $p5->page,          undef,     "limit 0 page ok";
is $p5->previous_page, undef, "limit 0 previous ok";
is $p5->next_page,     undef,     "limit 0 next ok";
is $p5->page_size,     0,    "limit 0 page size ok";
is $p5->first_on_page, 0,     "limit 0 first on page ok";
is $p5->last_on_page,  0,    "limit 0 last on page ok";
is $p5->last_page,     undef,     "limit 0 last page ok";
is_deeply $p5->pages_in_spread,     [],     "limit 0 has an empty page spread";

done_testing;
