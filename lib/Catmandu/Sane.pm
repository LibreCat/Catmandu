package Catmandu::Sane;
use strict;
use warnings;
use feature qw(:5.10);
use utf8;
use Scalar::Util ();
use Carp ();
use mro ();

sub import {
    my ($self, %opts) = @_;

    my $caller = caller;

    $opts{level} //= 1;

    strict->import;
    warnings->import;
    feature->import(':5.10');
    utf8->import;

    Scalar::Util->export_to_level($opts{level}, $caller, qw(blessed));
    Carp->export_to_level($opts{level}, $caller, qw(confess));

    mro::set_mro($caller, 'c3');
}

1;
