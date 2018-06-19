#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::include';
    use_ok $pkg;
}

{
    my $result = {
        name          => "Franck",
        first_name    => "Nicolas",
        working_place => "University Library of Ghent",
        hobbies       => ['cooking', 'art', 'hiking']
    };

    is_deeply($pkg->new("fix-level-1.fix")->fix({}),
        $result, "include fix at multiple levels");
}

{
    my $result = {'fix-1' => 'ok', 'fix-2' => 'ok', 'fix-3' => 'ok',};

    is_deeply($pkg->new("fix-include-glob/*.fix")->fix({}),
        $result, "include fixes with glob pattern");
}

done_testing;
