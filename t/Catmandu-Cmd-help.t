#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Cmd::help';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

{
	my $result = test_app(qq|Catmandu::CLI| => [ qw(help) ]);

	is $result->error, undef, 'threw no exceptions' ;
}

{
	my $result = test_app(qq|Catmandu::CLI| => [ qw(help importer JSON) ]);

	is $result->error, undef, 'threw no exceptions' ;
}

{
	my $result = test_app(qq|Catmandu::CLI| => [ qw(help exporter JSON) ]);

	is $result->error, undef, 'threw no exceptions' ;
}

{
	my $result = test_app(qq|Catmandu::CLI| => [ qw(help store Hash) ]);

	is $result->error, undef, 'threw no exceptions' ;
}

done_testing 6;