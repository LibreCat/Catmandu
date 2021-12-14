#!/usr/bin/env perl
use strict;
use utf8;
use warnings;
use Test::More;
use Test::Exception;
use IO::File;
use Catmandu::Importer::Mock;
use Catmandu::Util qw(:is);

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix';
    use_ok $pkg;
}
require_ok $pkg;

my $fixer = Catmandu::Fix->new(fixes => []);

ok $fixer , 'create a new fixer';

is_deeply $fixer->fix({}), {}, 'fixing hashes';
is_deeply $fixer->fix({name => 'value'}), {name => 'value'};
is_deeply $fixer->fix({name => {name => 'value'}}),
    {name => {name => 'value'}};
is_deeply $fixer->fix({name => [{name => 'value'}]}),
    {name => [{name => 'value'}]};

throws_ok {$fixer->fix(IO::File->new("<t/myfixes.fix"))} 'Catmandu::BadArg',
    'throws Catmandu::BadArg';

is_deeply $fixer->fix([]), [], 'fixing arrays';
is_deeply $fixer->fix([{name => 'value'}]), [{name => 'value'}];
is_deeply $fixer->fix([{name => {name => 'value'}}]),
    [{name => {name => 'value'}}];
is_deeply $fixer->fix([{name => [{name => 'value'}]}]),
    [{name => [{name => 'value'}]}];

ok $fixer->fix(Catmandu::Importer::Mock->new(size => 13)), 'fixing iterators';
my $it = $fixer->fix(Catmandu::Importer::Mock->new(size => 13));
can_ok $it , 'count';
is $it->count, 13;

my $gen_n = 3;
my $ref   = $fixer->fix(
    sub {
        return undef unless $gen_n--;
        return {n => $gen_n};
    }
);
ok $ref, 'fixing a coderef';
ok is_code_ref($ref);
is $ref->()->{n}, 2;
is $ref->()->{n}, 1;
is $ref->()->{n}, 0;
is $ref->(),      undef;

# test logging
can_ok $fixer , 'log';
isa_ok $fixer->log,          'Log::Any::Proxy';
isa_ok $fixer->log->adapter, 'Log::Any::Adapter::Null';

# test error handling
{

    package DieFix;
    use Moo;
    with 'Catmandu::Fix::Base';
    sub emit {'die;'}
}

$fixer = Catmandu::Fix->new(fixes => [DieFix->new]);
throws_ok {
    $fixer->fix({});
}
'Catmandu::FixError';

$fixer = Catmandu::Fix->new(fixes => ['t/myfixes.fix']);
ok $fixer;
is_deeply $fixer->fix({}),
    {utf8_name =>
        'ვეპხის ტყაოსანი შოთა რუსთაველი'
    }, 'fixing utf8';

open(FH, '<:encoding(UTF-8)', 't/myfixes.fix');
$fixer = Catmandu::Fix->new(fixes => [\*FH]);
ok $fixer;
is_deeply $fixer->fix({}),
    {utf8_name =>
        'ვეპხის ტყაოსანი შოთა რუსთაველი'
    }, 'fixing utf8';
close(FH);

$fixer = Catmandu::Fix->new(fixes => [IO::File->new('< t/myfixes.fix')]);
ok $fixer;
is_deeply $fixer->fix({}),
    {utf8_name =>
        'ვეპხის ტყაოსანი შოთა რუსთაველი'
    }, 'fixing utf8';

# get

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data.$first,test)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}),
    {data => [qw(0 1 2)], test => 0}, 'get $first test';

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data.$last,test)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}),
    {data => [qw(0 1 2)], test => 2}, 'get $last test';

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data.1,test)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}),
    {data => [qw(0 1 2)], test => 1}, 'get position test arary';

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data.1,test)']);
is_deeply $fixer->fix({data => {1 => 1}}), {data => {1 => 1}, test => 1},
    'get position test hash';

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data.*,test)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}),
    {data => [qw(0 1 2)], test => 2}, 'get star test arary';

# set

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data,test.1)']);
is_deeply $fixer->fix({data => 1}), {data => 1, test => [undef, 1]},
    'set position test';

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data,test.$first)']);
is_deeply $fixer->fix({data => 1, test => [qw(0 1 2)]}),
    {data => 1, test => [qw(1 1 2)]}, 'set $first test';

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data,test.$last)']);
is_deeply $fixer->fix({data => 1, test => [qw(0 1 2)]}),
    {data => 1, test => [qw(0 1 1)]}, 'set $last test';

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data,test.$prepend)']);
is_deeply $fixer->fix({data => 1, test => [qw(0 1 2)]}),
    {data => 1, test => [qw(1 0 1 2)]}, 'set $prepend test';

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data,test.$append)']);
is_deeply $fixer->fix({data => 1, test => [qw(0 1 2)]}),
    {data => 1, test => [qw(0 1 2 1)]}, 'set $append test';

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data,test.*)']);
is_deeply $fixer->fix({data => 1, test => [qw(0 1 2)]}),
    {data => 1, test => [qw(1 1 1)]}, 'set star test';

$fixer = Catmandu::Fix->new(fixes => ['copy_field(data,test.1)']);
is_deeply $fixer->fix({data => 1, test => {}}),
    {data => 1, test => {1 => 1}}, 'set hash test';

# non matching paths are ignored

$fixer = Catmandu::Fix->new(fixes => ['upcase(data.0)']);
is_deeply $fixer->fix({}), {}, 'non matching paths are ignored';

# delete

$fixer = Catmandu::Fix->new(fixes => ['remove_field(data.$first)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}), {data => [qw(1 2)]},
    'remove $first test';

$fixer = Catmandu::Fix->new(fixes => ['remove_field(data.$last)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}), {data => [qw(0 1)]},
    'remove $last test';

$fixer = Catmandu::Fix->new(fixes => ['remove_field(data.1)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}), {data => [qw(0 2)]},
    'remove position test arary';

$fixer = Catmandu::Fix->new(fixes => ['remove_field(data.1)']);
is_deeply $fixer->fix({data => {1 => 1}}), {data => {}},
    'remove position test hash';

$fixer = Catmandu::Fix->new(fixes => ['remove_field(data.*)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}), {data => []},
    'remove star test arary';

# retain

$fixer = Catmandu::Fix->new(fixes => ['retain_field(data.$first)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}), {data => [qw(0)]},
    'retain_field $first test';

$fixer = Catmandu::Fix->new(fixes => ['retain_field(data.$last)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}), {data => [qw(2)]},
    'retain_field $last test';

$fixer = Catmandu::Fix->new(fixes => ['retain_field(data.1)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}), {data => [qw(1)]},
    'retain_field position test arary';

$fixer = Catmandu::Fix->new(fixes => ['retain_field(data.1)']);
is_deeply $fixer->fix({data => {1 => 1, 2 => 2}}), {data => {1 => 1}},
    'retain_field position test hash';

$fixer = Catmandu::Fix->new(fixes => ['retain_field(data.*)']);
is_deeply $fixer->fix({data => [qw(0 1 2)]}), {data => [qw(0 1 2)]},
    'retain_field star test arary';

$fixer = Catmandu::Fix->new(fixes => ['retain_field(data.*)']);
is_deeply $fixer->fix({data => {1 => 1, 2 => 2}}),
    {data => {1 => 1, 2 => 2}}, 'retain_field star test hash';

# path delimiter escapes

$fixer = Catmandu::Fix->new(fixes => [q|add_field('with\.a\.dot', Train)|]);
is_deeply $fixer->fix({}), {'with.a.dot' => 'Train'}, "add field with.a.dot";
$fixer = Catmandu::Fix->new(fixes => [q|copy_field('with\.a.dot', no.dot)|]);
is_deeply $fixer->fix({'with.a' => {'dot' => 'Train'}}),
    {'no' => {'dot' => 'Train'}, 'with.a' => {'dot' => 'Train'}},
    "move field with a dot to one without";

# preprocessing and variables

$fixer = Catmandu::Fix->new(
    fixes      => ['t/variables.fix'],
    preprocess => 1,
    variables  => {
        source => 'field1',
        target => 'field2',
        others => [qw(0 1)],
        beer   => 1,
        milk   => 0,
    }
);

is_deeply $fixer->fix({field1 => 'value'}),
    {field2 => 'value', other_0 => 0, other_1 => 1, drunk => 'yes'},
    'preprocessing: variable interpolation';

done_testing;
