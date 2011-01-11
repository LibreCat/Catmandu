package Catmandu::App::Declare;
# VERSION
use strict;
use warnings;
use Catmandu;
use Catmandu::App;

sub import {
    strict->import;
    warnings->import;

    my $pkg = caller;

    no strict 'refs';
}

1;

