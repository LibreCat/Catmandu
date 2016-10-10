use strict;
use warnings;

use Test::More;

## no critic
eval 'use Test::Code::TidyAll 0.20';
plan skip_all =>
    "Test::Code::TidyAll 0.20 required to check if the code is clean."
    if $@;
tidyall_ok();
