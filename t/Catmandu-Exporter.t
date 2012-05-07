#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::ExporterWithoutAdd;
    use Moo;

    package T::Exporter;
    use Moo;
    with $pkg;

    sub add {}

}

throws_ok { Role::Tiny->apply_role_to_package('T::ExporterWithoutAdd', $pkg) } qr/missing add/;

my $e = T::Exporter->new;
ok $e->does('Catmandu::Addable');
ok $e->does('Catmandu::Counter');
can_ok $e, 'encoding';
can_ok $e, 'commit';

is $e->encoding, ':utf8';

$e->add(1);
is $e->count, 1;
$e->add_many([2,3,4]);
is $e->count, 4;

done_testing 10;

