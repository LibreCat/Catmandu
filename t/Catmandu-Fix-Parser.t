#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;
use Catmandu::Fix;
use Catmandu::Fix::upcase;
use Catmandu::Fix::downcase;
use Catmandu::Fix::reject;
use Catmandu::Fix::Condition::exists;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Parser';
    use_ok $pkg;
}

my $parser = $pkg->new;

isa_ok $parser, $pkg;
can_ok $parser, 'parse';

lives_ok {$parser->parse("")} 'parse empty string';
lives_ok {$parser->parse("    \n    ")} 'parse whitespace only string';
dies_ok {$parser->parse("if exists(foo)")} 'die on if without end';
dies_ok {$parser->parse("if end")} 'die on if without condition';
dies_ok {$parser->parse("unless exists(foo)")} 'die on unless without end';
dies_ok {$parser->parse("unless end")} 'die on unless without condition';
dies_ok {$parser->parse("foo()")} 'die on unknown fix';

my $foo_exists   = Catmandu::Fix::Condition::exists->new("foo");
my $bar_exists   = Catmandu::Fix::Condition::exists->new("bar");
my $baz_exists   = Catmandu::Fix::Condition::exists->new("baz");
my $upcase_foo   = Catmandu::Fix::upcase->new("foo");
my $downcase_foo = Catmandu::Fix::downcase->new("foo");
my $upcase_bar   = Catmandu::Fix::upcase->new("bar");
my $downcase_bar = Catmandu::Fix::downcase->new("bar");
my $reject       = Catmandu::Fix::reject->new;

cmp_deeply $parser->parse(""), [];

cmp_deeply $parser->parse(
    "# a comment
    # another comment
    #
    downcase(foo) # yet another comment"
    ),
    [$downcase_foo,],
    "comments";

cmp_deeply $parser->parse("upcase(foo)"), [$upcase_foo,];

cmp_deeply $parser->parse(q|upcase('foo')|), [$upcase_foo,];

cmp_deeply $parser->parse(q|upcase("foo")|), [$upcase_foo,];

cmp_deeply $parser->parse("upcase(foo) downcase(foo)"),
    [$upcase_foo, $downcase_foo,];

cmp_deeply $parser->parse("upcase(foo) downcase(foo)"),
    $parser->parse("upcase(foo); downcase(foo)");

cmp_deeply $parser->parse("upcase(foo) downcase(foo)"),
    $parser->parse("upcase(foo); downcase(foo);");

cmp_deeply $parser->parse("if exists(foo) end"), [$foo_exists,];

$foo_exists->pass_fixes([$downcase_foo]);
$foo_exists->fail_fixes([]);
cmp_deeply $parser->parse("if exists(foo) downcase(foo) end"), [$foo_exists,];

$foo_exists->pass_fixes([$downcase_foo]);
$foo_exists->fail_fixes([$upcase_foo]);
cmp_deeply $parser->parse(
    "if exists(foo) downcase(foo) else upcase(foo) end"), [$foo_exists,];

$foo_exists->pass_fixes([]);
$foo_exists->fail_fixes([$downcase_foo]);
cmp_deeply $parser->parse("unless exists(foo) downcase(foo) end"),
    [$foo_exists,];

$foo_exists->pass_fixes([$bar_exists, $upcase_foo]);
$foo_exists->fail_fixes([]);
$bar_exists->pass_fixes([$downcase_foo]);
$bar_exists->fail_fixes([]);
cmp_deeply $parser->parse(
    "if exists(foo) if exists(bar) downcase(foo) end upcase(foo) end"),
    [$foo_exists,];

# with optional deprecated separators
cmp_deeply $parser->parse(
    "if exists(foo); if exists(bar); downcase(foo); end; upcase(foo); end;"),
    [$foo_exists,];

# if ... elsif
$bar_exists->pass_fixes([$upcase_foo]);
$bar_exists->fail_fixes([]);
$foo_exists->pass_fixes([$downcase_foo]);
$foo_exists->fail_fixes([$bar_exists]);
cmp_deeply $parser->parse(
    "if exists(foo) downcase(foo) elsif exists(bar) upcase(foo) end"),
    [$foo_exists,];

# if ... elsif ... else
$bar_exists->pass_fixes([$upcase_foo]);
$bar_exists->fail_fixes([$upcase_bar]);
$foo_exists->pass_fixes([$downcase_foo]);
$foo_exists->fail_fixes([$bar_exists]);
cmp_deeply $parser->parse(
    "if exists(foo) downcase(foo) elsif exists(bar) upcase(foo) else upcase(bar) end"
), [$foo_exists,];

# if ... elsif ... elsif ... else
$baz_exists->pass_fixes([$upcase_bar]);
$baz_exists->fail_fixes([$downcase_bar]);
$bar_exists->pass_fixes([$upcase_foo]);
$bar_exists->fail_fixes([$baz_exists]);
$foo_exists->pass_fixes([$downcase_foo]);
$foo_exists->fail_fixes([$bar_exists]);
cmp_deeply $parser->parse(
    "if exists(foo) downcase(foo) elsif exists(bar) upcase(foo) elsif exists(baz) upcase(bar) else downcase(bar) end"
), [$foo_exists,];

# and, or
$foo_exists->pass_fixes([$downcase_foo]);
$foo_exists->fail_fixes([]);
cmp_deeply $parser->parse("exists(foo) and downcase(foo)"), [$foo_exists,];
cmp_deeply $parser->parse("exists(foo) && downcase(foo)"),  [$foo_exists,];
cmp_deeply $parser->parse("exists(foo) && downcase(foo);"), [$foo_exists,];

$foo_exists->pass_fixes([]);
$foo_exists->fail_fixes([$downcase_bar]);
cmp_deeply $parser->parse("exists(foo) or downcase(bar)"), [$foo_exists,];
cmp_deeply $parser->parse("exists(foo) || downcase(bar)"), [$foo_exists,];

$foo_exists->pass_fixes([$upcase_foo]);
$foo_exists->fail_fixes([]);
$bar_exists->pass_fixes([$upcase_bar]);
$bar_exists->fail_fixes([]);
cmp_deeply $parser->parse(
    "exists(foo) && upcase(foo) exists(bar) && upcase(bar)"),
    [$foo_exists, $bar_exists,];
cmp_deeply $parser->parse(
    "exists(foo) && upcase(foo); exists(bar) && upcase(bar)"),
    [$foo_exists, $bar_exists,];

dies_ok {$parser->parse("exists(foo) || if exists(foo) downcase(foo) end")}
'die on bool without fix';
dies_ok {$parser->parse("|| downcase(foo)")} 'die on bool without condition';

# select, reject
$foo_exists->pass_fixes([]);
$foo_exists->fail_fixes([$reject]);
cmp_deeply $parser->parse("select exists(foo)"), [$foo_exists,];

$foo_exists->pass_fixes([$reject]);
$foo_exists->fail_fixes([]);
cmp_deeply $parser->parse("reject exists(foo)"), [$foo_exists,];

throws_ok {
    $parser->parse('unknown_fix()');
}
'Catmandu::NoSuchFixPackage', 'using unknown fixes throws NoSuchFixPackage';

throws_ok {
    $parser->parse('copy_field()');
}
'Catmandu::BadFixArg', 'missing or bad fix arguments throw BadFixArg';

throws_ok {
    $parser->parse('syntax_error((((((');
}
'Catmandu::FixParseError', 'syntax errors throw FixParseError';

# bare strings

{
    my $fixes = $parser->parse(q|add_field(022, 022)|);
    my $path  = $fixes->[0]->path;
    is "$path", '022';
}

# string and regex escapes

{
    my $fixes;
    lives_ok {
        $parser->parse(q|set_field(test, "\"")|);
    };
    dies_ok {
        $parser->parse(q|set_field(test, "\\\\"")|);
    };
    lives_ok {
        $parser->parse(q|set_field(test, '\'')|);
    };
    dies_ok {
        $parser->parse(q|set_field(test, '\\\\'')|);
    };
    lives_ok {
        $parser->parse(q|replace_all(test, '\+(\d{2}):(\d{2})', '+$1$2')|);
    };
    lives_ok {
        $fixes = $parser->parse(
            q|replace_all(test, '\+(\d{2}):(\d{2})', '+$1$2')|);
    };
    is $fixes->[0]->search, '\+(\d{2}):(\d{2})';
    $fixes
        = $parser->parse(q|replace_all(test, "\+(\d{2}):(\d{2})", "+$1$2")|);
    is $fixes->[0]->search,  '\+(\d{2}):(\d{2})';
    is $fixes->[0]->replace, '+$1$2';
}

done_testing;
