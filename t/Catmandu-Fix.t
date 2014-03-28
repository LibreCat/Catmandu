#!/usr/bin/env perl
use strict;
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

my $ref =$fixer->fix(generator());
ok $ref, 'fixing a coderef';
ok is_code_ref($ref);
is $ref->()->{n} , 2;
is $ref->()->{n} , 1;
is $ref->()->{n} , 0;
is $ref->() , undef;

can_ok $fixer , 'log';
isa_ok $fixer->log , 'Log::Any::Adapter::Null';

done_testing 22;

sub generator {
	my $size = 3;
	sub {
		return undef unless $size--;
		return {n => $size};
	}	
}
