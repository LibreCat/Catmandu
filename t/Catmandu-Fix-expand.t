#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::expand';
    use_ok $pkg;
}

is_deeply $pkg->new->fix({'names.0.name' => "joe", 'names.1.name' => "rick"}),
    {names => [{name => 'joe'}, {name => 'rick'}]}, "data is unflattened";

is_deeply $pkg->new('sep', '-')
    ->fix({'names-0-name' => "joe", 'names-1-name' => "rick"}),
    {names => [{name => 'joe'}, {name => 'rick'}]}, "data is unflattened";

lives_ok {
    my %flat = map {("list.$_" => $_)} 0 .. 9999;
    my $deep = $pkg->new->fix(\%flat);
    die unless @{$deep->{list}} == 10000;
}
"expand large arrays";

done_testing;
