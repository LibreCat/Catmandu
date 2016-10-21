use strict;
use warnings;
use Test::More;
use Test::Exception;

my $add;
my $copy;

BEGIN {
    $add = 'Catmandu::Fix::add_field';
    use_ok $add;
    $copy = 'Catmandu::Fix::copy_field';
    use_ok $copy;
}

is_deeply $add->new('with\.a\.dot', 'Train')->fix({}),
    {'with.a.dot' => 'Train'}, "add field with.a.dot";

is_deeply $copy->new('with\.a.dot', 'no.dot')->fix({'with.a' => {'dot' => 'Train'}}),
    {'no' => {'dot' => 'Train'}, 'with.a' => {'dot' => 'Train'}}, "move field with a dot to one without";

done_testing 4;
