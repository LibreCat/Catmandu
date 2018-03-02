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

my @arguments = (
    [qw(help)], [qw(importer JSON)], [qw(exporter JSON)], [qw(store Hash)],
    [qw(fix set_field)], [qw(bind maybe)], [qw(condition exists)],
);

foreach my $args (@arguments) {
    my $result = test_app(qq|Catmandu::CLI| => $args);
    is $result->error, undef, join ' ', qw(catmandu help), @$args;
}

done_testing 2 + @arguments;
