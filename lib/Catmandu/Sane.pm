package Catmandu::Sane;

use strict;
use warnings;
use feature ();
use utf8;
use Try::Tiny::ByClass;
use Catmandu::Error;

sub import {
    my $pkg = caller;
    strict->import;
    warnings->import;
    feature->import(qw(:5.10));
    utf8->import;
    Try::Tiny::ByClass->export_to_level(1, $pkg);
}

1;

=head1 NAME

Catmandu::Sane - Package boilerplate

=head1 SYNOPSIS

    use Catmandu::Sane;

=head1 DESCRIPTION

Package boilerplate equivalent to:

    use strict;
    use warnings;
    use feature qw(:5.10);
    use utf8;
    use Try::Tiny::ByClass;
    use Catmandu::Error;

=cut
