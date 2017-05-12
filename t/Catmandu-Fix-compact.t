use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::compact';
    use_ok $pkg;
}

is_deeply $pkg->new('dirty_array')
    ->fix({'dirty_array' => [undef, undef, 'hello', undef, 'world', undef]}),
    {'dirty_array' => ['hello', 'world']}, "compact array";

done_testing;
