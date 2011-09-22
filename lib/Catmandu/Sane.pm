package Catmandu::Sane;
use strict;
use warnings;
use 5.010;
use feature ();
use utf8;
use Scalar::Util ();
use Carp ();

sub import {
    my $pkg = caller;

    strict->import;
    warnings->import;
    feature->import(':5.10');
    utf8->import;
    Scalar::Util->export_to_level(1, $pkg, qw(blessed));
    Carp->export_to_level(1, $pkg, qw(confess));
}

1;

=head1 NAME

Catmandu::Sane - Sensible package boilerplate

=head1 SYNOPSIS

    use Catmandu::Sane;

=head1 DESCRIPTION

Sensible package boilerplate equivalent to:

    use strict;
    use warnings;
    use 5.010;
    use utf8;
    use Scalar::Util qw(blessed);
    use Carp qw(confess);

=cut
