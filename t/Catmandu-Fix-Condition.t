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
my $fixes_old;

# ALL_MATCH
$fixes_old = "if_all_match('oogly.*', 'doogly');upcase('foo');end();";

ok $fixer = Catmandu::Fix->new(fixes => [$fixes_old]);

is_deeply
    $fixer->fix({ foo=>'low', oogly => ['doogly'] }),
    { foo=>'LOW', oogly => ['doogly'] },
    "if_all_match - check all match";

is_deeply
    $fixer->fix({ foo=>'low', oogly => ['doogly' , '!doogly!' ]}),
    { foo=>'LOW', oogly => ['doogly','!doogly!'] },
    "if_all_match - check all match (2)";

is_deeply
    $fixer->fix({ foo=>'low', oogly => ['doogly' , 'something' ]}),
    { foo=>'low', oogly => ['doogly','something'] },
    "if_all_match - check not all match";

is_deeply
    $fixer->fix({ foo=>'low' }),
    { foo=>'low' },
    "if_all_match - check no match";

# ANY_MATCH
$fixes_old = "if_any_match('oogly.*', 'doogly');upcase('foo');end();";

ok $fixer = Catmandu::Fix->new(fixes => [$fixes_old]);

is_deeply
    $fixer->fix({ foo=>'low', oogly => ['doogly'] }),
    { foo=>'LOW', oogly => ['doogly'] },
    "if_any_match - check all match";

is_deeply
    $fixer->fix({ foo=>'low', oogly => ['doogly' , '!doogly!' ]}),
    { foo=>'LOW', oogly => ['doogly','!doogly!'] },
    "if_any_match - check all match (2)";

is_deeply
    $fixer->fix({ foo=>'low', oogly => ['doogly' , 'something' ]}),
    { foo=>'LOW', oogly => ['doogly','something'] },
    "if_any_match - check not all match";

is_deeply
    $fixer->fix({ foo=>'low' }),
    { foo=>'low' },
    "if_any_match - check no match";

# EXISTS
$fixes_old = "if_exists('oogly');upcase('foo');end();";

ok $fixer = Catmandu::Fix->new(fixes => [$fixes_old]);

is_deeply
    $fixer->fix({ foo=>'low', oogly => ['doogly'] }),
    { foo=>'LOW', oogly => ['doogly'] },
    "if_exists - check  match";

is_deeply
    $fixer->fix({ foo=>'low' }),
    { foo=>'low' },
    "if_exists - check no match";

done_testing 15;
