package Catmandu::Importer;

use Catmandu::Sane;
use Catmandu::Util qw(io);
use Moo::Role;

with 'Catmandu::Iterable';

has file => (
    is      => 'ro',
    lazy    => 1,
    default => sub { \*STDIN },
);

has fh => (
    is      => 'ro',
    lazy    => 1,
    default => sub { io($_[0]->file, mode => 'r', encoding => $_[0]->encoding) },
);

sub encoding { ':utf8' }

=head1 NAME

Catmandu::Importer - Namespace for packages that can import

=head1 SYNOPSIS

    use Catmandu::Importer::JSON;

    my $importer = Catmandu::Importer::JSON->new(file => "/foo/bar.json");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 DESCRIPTION

A Catmandu::Importer is a stub for Perl packages that can import data from 
an external source (a file, the network, ...). An importer needs to implement
the 'each' method.

=head1 METHODS

=head2 each(&callback)

The each method should import data and execute the callback function for
each item imported. Returns the number of items imported or undef on 
failure.

=head1 SEE ALSO

L<Catmandu::Importer::Atom>,
L<Catmandu::Importer::CSV>,
L<Catmandu::Importer::JSON>,
L<Catmandu::Importer::OAI.pm>,
L<Catmandu::Importer::Spreadsheet.pm>,
L<Catmandu::Importer::YAML>

=cut

1;
