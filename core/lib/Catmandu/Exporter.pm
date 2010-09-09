package Catmandu::Exporter;

use strict;
use warnings;
use Carp;

sub open {
    my ($pkg, $format, @args) = @_;

    $format or croak "Export format missing";
    $pkg = "Catmandu::Exporter::$format";
    eval "require $pkg" or croak "Failed to load exporter '$pkg'";
    $pkg->open(@args);
}

sub write {
    0;
}

sub close {
    1;
}

1;

__END__

=head1 NAME

 Catmandu::Exporter - [FILL IN THE PURPOSE]

=head1 SYNOPSIS

 [FILL IN EXAMPLE USAGE]

=head1 DESCRIPTION

 [FILL IN TEXTUAL DESCRIPTION OF THIS PACKAGE]

=head1 METHODS

=over 4

=item method1

[DOCUMENTATION]

=item method2

[DOCUMENTATION]

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
