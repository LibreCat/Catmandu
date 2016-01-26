#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;
use Capture::Tiny ':all';
use Catmandu::Util qw(:is);

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Bind::importer';
    use_ok $pkg;
}
require_ok $pkg;

{
	my ($stdout, $stderr, $exit) = capture {
	     my $fixer = Catmandu->fixer('do importer(Mock,size:1) add_to_exporter(.,JSON) end');
	     $fixer->fix({});
	};

	is $stdout, qq|[{"n":0}]\n| , 'fixed ok';
}

{
	my ($stdout, $stderr, $exit) = capture {
	     my $fixer = Catmandu->fixer('do importer(Mock,size:1) reject() end');
	     $fixer->fix({});
	};

	is $stdout, qq||, 'fixed ok';
}

{
	my ($stdout, $stderr, $exit) = capture {
	     my $fixer = Catmandu->fixer('do importer(Mock,size:1) select exists(n) end');
	     $fixer->fix({});
	};

	is $stdout, qq||, 'fixed ok';
}

done_testing;
