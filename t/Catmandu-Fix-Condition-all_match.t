#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Catmandu::Fix::set_field;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Condition::all_match';
    use_ok $pkg;
}

{
	my $cond = $pkg->new('foo','abc');
	$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
	$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

	is_deeply
	    $cond->fix({foo => qw(abc)}),
	    {foo => qw(abc), test => 'pass'};

	is_deeply
	    $cond->fix({foo => qw(cbc)}),
	    {foo => qw(cbc), test => 'fail'};
}

{
	my $cond = $pkg->new('foo.*','abc');
	$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
	$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

	is_deeply
	    $cond->fix({foo => [qw(abc)]}),
	    {foo =>  [qw(abc)], test => 'pass'};

	is_deeply
	    $cond->fix({foo => [qw(abc abc)]}),
	    {foo => [qw(abc abc)], test => 'pass'};

	is_deeply
	    $cond->fix({foo => [qw(abc cbc)]}),
	    {foo => [qw(abc cbc)], test => 'fail'};
}

done_testing 6;
