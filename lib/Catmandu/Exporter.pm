package Catmandu::Exporter;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(io);
use Moo::Role;

with 'MooX::Log::Any';
with 'Catmandu::Addable';
with 'Catmandu::Counter';

has file => (
    is      => 'ro',
    lazy    => 1,
    default => sub { \*STDOUT },
);

has fh => (
    is      => 'ro',
    lazy    => 1,
    default => sub { io($_[0]->file, mode => 'w', binmode => $_[0]->encoding) },
);

after add => sub {
    $_[0]->inc_count;
};

sub encoding { ':utf8' }

=head1 NAME

Catmandu::Exporter - Namespace for packages that can export a hashref or an iterable object

=head1 SYNOPSIS

    use Catmandu::Exporter::YAML;

    my $exporter = Catmandu::Exporter::YAML->new(fix => 'myfix.txt');

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d objects\n" , $exporter->count;

=head1 METHODS

=head2 new(file => PATH, fh => HANDLE, fix => STRING|ARRAY)

Create a new Catmandu::Exporter. When no options are given exported data is written to
the stdout. Optionally provide a 'file' pathname or a 'fh' file handle to redirect the
ouput.

Every Catmandu::Exporter is a L<Catmandu::Fixable> and thus provides a 'fix' parameter that
can be set in the constructor. For every 'add' or for every item in 'add_many' the given
fixes will be applied first.

=head2 add($hashref)

Adds one object to be exported. Provide a HASH-ref or an L<Catmandu::Iterator> to loop. 
Returns a true value when the export was successful or undef on error.

=head2 add_many($arrayref)

=head2 add_many($iterator)

=head2 add_many(sub {})

Provide one or more objects to be exported. The exporter will use array references, iterators
and generator routines to loop over all items. Returns the total number of items exported.

=head2 count

Returns the number of items exported by this Catmandu::Exporter.

=head2 log

Return the current logger.

=head1 SEE ALSO

L<Catmandu::Exporter::Fix>

=cut

1;
