package Catmandu::Importer;

use Catmandu::Proxy;

proxy 'each';

__PACKAGE__->meta->make_immutable;
no Catmandu::Proxy;
no Mouse;

__END__

=head1 NAME

 Catmandu::Importer - An importer of bibliographic data structures.

=head1 SYNOPSIS

 $importer = Catmandu::Importer->new('JSON', io => $io);

 $importer->each(sub {
    my $obj = $_[0];
    ...
 });

 $ok = $importer->done;

=head1 METHODS

=over 4

=item new($driver_pkg, @args)

Contructs a new exporter. Passes @args to the driver instance.
C<$driver_pkg> is assumed to live in the Catmandu::Exporter
namespace unless full a package name is given.

=item driver()

Returns the underlying driver.

=item each(\&callback)

Loops over all objects in the stream and passes them to C<callback>. Returns the number of processed objects.

=item done()

Explicitly teardown the driver. This method is called at
C<DESTROY> time. Returns 1 or 0.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
