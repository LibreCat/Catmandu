use strict;
use warnings;
use Catmandu::Fix;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition';
    use_ok $pkg;
}
require_ok $pkg;

my $fixer;
my $fixes;

# ALL_MATCH
$fixes = "if all_match('oogly.*', 'doogly') upcase('foo') end";

ok $fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'low', oogly => ['doogly']}),
    {foo => 'LOW', oogly => ['doogly']}, "if all_match - check all match";

is_deeply $fixer->fix({foo => 'low', oogly => ['doogly', '!doogly!']}),
    {foo => 'LOW', oogly => ['doogly', '!doogly!']},
    "if all_match - check all match (2)";

is_deeply $fixer->fix({foo => 'low', oogly => ['doogly', 'something']}),
    {foo => 'low', oogly => ['doogly', 'something']},
    "if all_match - check not all match";

is_deeply $fixer->fix({foo => 'low'}), {foo => 'low'},
    "if all_match - check no match";

# ANY_MATCH
$fixes = "if any_match('oogly.*', 'doogly') upcase('foo') end";

ok $fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'low', oogly => ['doogly']}),
    {foo => 'LOW', oogly => ['doogly']}, "if any_match - check all match";

is_deeply $fixer->fix({foo => 'low', oogly => ['doogly', '!doogly!']}),
    {foo => 'LOW', oogly => ['doogly', '!doogly!']},
    "if any_match - check all match (2)";

is_deeply $fixer->fix({foo => 'low', oogly => ['doogly', 'something']}),
    {foo => 'LOW', oogly => ['doogly', 'something']},
    "if any_match - check not all match";

is_deeply $fixer->fix({foo => 'low'}), {foo => 'low'},
    "if any_match - check no match";

# EXISTS
$fixes = "if exists('oogly') upcase('foo') end";

ok $fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'low', oogly => ['doogly']}),
    {foo => 'LOW', oogly => ['doogly']}, "if exists - check match";

is_deeply $fixer->fix({foo => 'low'}), {foo => 'low'},
    "if exists - check no match";

# USE AS INLINE FIX
{
    use Catmandu::Fix::Condition::exists as => 'has_field';
    my $item = {foo => {bar => 1}};
    ok has_field($item,  'foo.bar'), 'inline condition - true';
    ok !has_field($item, 'doz'),     'inline condition - false';
}

done_testing;
