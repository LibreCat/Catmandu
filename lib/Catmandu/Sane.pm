package Catmandu::Sane;
use strict;
use warnings;
use feature qw(:5.10);
use utf8;
use Carp ();
use Try::Tiny ();
use mro ();

sub import {
    my ($self, %opts) = @_;

    my $caller = caller;

    $opts{level} //= 1;

    strict->import;
    warnings->import;
    feature->import(':5.10');
    utf8->import;

    Carp->export_to_level($opts{level}, $caller, qw(confess));
    Try::Tiny->export_to_level($opts{level}, $caller, qw(try catch finally));

    mro::set_mro($caller, 'c3');
}

1;
