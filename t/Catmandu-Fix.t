#!/usr/bin/env perl
use strict;
use utf8;
use warnings;
use Test::More;
use Test::Exception;
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

is_deeply $fixer->fix({}) , {} , 'fixing hashes';
is_deeply $fixer->fix({name => 'value'}) , {name => 'value'};
is_deeply $fixer->fix({name => { name => 'value'} }) , {name => { name => 'value'} };
is_deeply $fixer->fix({name => [ { name => 'value'} ] }) , { name => [ { name => 'value'} ] };

is_deeply $fixer->fix([]), [] , 'fixing arrays';
is_deeply $fixer->fix([{name => 'value'}]) , [{name => 'value'}];
is_deeply $fixer->fix([{name => { name => 'value'} }]) , [{name => { name => 'value'} }];
is_deeply $fixer->fix([{name => [ { name => 'value'} ] }]) , [{ name => [ { name => 'value'} ] }];

ok $fixer->fix(Catmandu::Importer::Mock->new(size=>13)) , 'fixing iterators';
my $it = $fixer->fix(Catmandu::Importer::Mock->new(size=>13));
can_ok $it , 'count';
is $it->count , 13;

my $gen_n = 3;
my $ref =$fixer->fix(sub {
    return undef unless $gen_n--;
    return {n => $gen_n};
});
ok $ref, 'fixing a coderef';
ok is_code_ref($ref);
is $ref->()->{n} , 2;
is $ref->()->{n} , 1;
is $ref->()->{n} , 0;
is $ref->() , undef;

# test logging
can_ok $fixer , 'log';
isa_ok $fixer->log , 'Log::Any::Proxy';
isa_ok $fixer->log->adapter , 'Log::Any::Adapter::Null';

# test error handling
{
    package DieFix;
    use Moo;
    with 'Catmandu::Fix::Base';
    sub emit { 'die;' }
}

$fixer = Catmandu::Fix->new(fixes => [DieFix->new]);
throws_ok {
    $fixer->fix({});
} 'Catmandu::FixError';

$fixer = Catmandu::Fix->new(fixes => ['t/myfixes.fix']);
ok $fixer;
is_deeply $fixer->fix({}), {utf8_name => 'ვეპხის ტყაოსანი შოთა რუსთაველი'} , 'fixing utf8';

open(FH,'<:encoding(UTF-8)','t/myfixes.fix');
$fixer = Catmandu::Fix->new(fixes => [\*FH]);
ok $fixer;
is_deeply $fixer->fix({}), {utf8_name => 'ვეპხის ტყაოსანი შოთა რუსთაველი'} , 'fixing utf8';
close(FH);

done_testing 28;