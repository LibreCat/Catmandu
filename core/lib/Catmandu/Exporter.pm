package Catmandu::Exporter;

use Catmandu::Proxy;

proxy 'write';

__PACKAGE__->meta->make_immutable;
no Catmandu::Proxy;
no Mouse;

__END__

=head1 NAME

 Catmandu::Exporter - An exporter for bibliographic data structures.

=head1 SYNOPSIS

 $exporter = Catmandu::Exporter->new('JSON', io => $io);

 $count = $exporter->write({foo => 'bar});
 $exporter->write(['foo', 'bar']);
 $exporter->write($obj); # export an object that understands 'each'

 $ok = $exporter->done;

=head1 METHODS

=over 4

=item new($driver_pkg, @args)

Contructs a new exporter. Passes @args to the driver instance.
C<$driver_pkg> is assumed to live in the Catmandu::Exporter
namespace unless full a package name is given.

=item driver()

Returns the underlying driver.

=item write($obj)

Exports C<$obj>. C<$obj> can be a hashref, arrayref or an object
with an C<each> method.

=item done()

Explicitly teardown the driver. This method is called at
C<DESTROY> time. Returns 1 or 0.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
