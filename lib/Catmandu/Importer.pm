package Catmandu::Importer;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(io);
use Moo::Role;

with 'MooX::Log::Any';
with 'Catmandu::Iterable';
with 'Catmandu::Fixable';

around generator => sub {
    my ($orig, $self) = @_;
    my $generator = $orig->($self);
    if (my $fixer = $self->_fixer) {
        return $fixer->fix($generator);
    }
    $generator;
};

has file => (
    is      => 'ro',
    lazy    => 1,
    default => sub { \*STDIN },
);

has fh => (
    is      => 'ro',
    lazy    => 1,
    default => sub { io($_[0]->file, mode => 'r', binmode => $_[0]->encoding) },
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

Every Catmandu::Importer is a Catmandu::Fixable and thus provides a 'fix' parameter that
can be set in the constructor. For every item returned by the generator the given fixes
will be applied first.

=head1 METHODS

=head2 new(file => $file , encoding => $encoding )

=head2 new(fh => $fh)

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited.

=head2 log

Return the current logger.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
