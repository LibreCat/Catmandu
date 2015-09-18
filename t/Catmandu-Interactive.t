#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Util;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Interactive';
    use_ok $pkg;
}
require_ok $pkg;

{
	my $in = text_in("/q\n");
	my $text = "";
	my $out = text_out(\$text);

	my $app = Catmandu::Interactive->new(in => $in, out => $out, silent => 1);

	$app->run();

	is $text , "", 'app runs';
}

{
	my $in = text_in("add_field(hello,world)\n");
	my $text = "";
	my $out = text_out(\$text);

	my $app = Catmandu::Interactive->new(in => $in, out => $out, silent => 1, exporter => 'JSON');

	$app->run();

	is $text , "{\"hello\":\"world\"}\n", 'can execute hello world';
}

done_testing 4;

sub text_in {
	my $text = shift;
	my $fh   = Catmandu::Util::io \$text, mode => 'r';
	$fh;
}

sub text_out {
	my $fh   = Catmandu::Util::io shift, mode => 'w';
	$fh;
}