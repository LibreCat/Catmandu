#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Serializer';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::Serializer;
    use Moo;
    with $pkg;
}

my $t = T::Serializer->new;

can_ok $t, qw(serialize deserialize serializer serialization_format);
isa_ok $t->serializer, 'Catmandu::Serializer::json';

my $data = {foo => 'bar'};

is_deeply $data, $t->deserialize($t->serialize($data));

$t = T::Serializer->new(serialization_format => 'dumper');

isa_ok $t->serializer, 'Catmandu::Serializer::dumper';

done_testing 6;

