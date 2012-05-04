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
an external source (a file, the network, ...). 

=head1 METHODS

=head2 new(file => $file , encoding => $encoding )

=head2 new(fh => $fh)

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;