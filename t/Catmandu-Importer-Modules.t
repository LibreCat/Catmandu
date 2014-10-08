#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::Modules';
    use_ok $pkg;
}
require_ok $pkg;

my $importer;
my $modules;

lives_ok(sub{
    $importer = Catmandu::Importer::Modules->new(
        inc => ["lib"],
        namespace => "Catmandu::Fix",
        max_depth => 1,
        pattern => qr/add_field/
    );
});
lives_ok(sub{
    $modules = $importer->to_array();
});

ok(ref($modules) && ref($modules) eq "ARRAY" && scalar(@$modules) > 0);

is $modules->[0]->{name},"Catmandu::Fix::add_field";

done_testing 6;
