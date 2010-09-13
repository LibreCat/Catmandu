package Catmandu::Importer;

use Mouse;

has 'driver' => (is => 'ro', required => 1, handles => [qw(each done)]);

sub BUILDARGS {
    my ($pkg, $driver_pkg, @args) = @_;
    $driver_pkg or confess "Driver is required";
    if ($driver_pkg !~ /::/) {
        $driver_pkg = "$pkg::$driver_pkg";
    }
    eval { Mouse::Util::load_class($driver_pkg) } or
        confess "Can't load driver $driver_pkg";
    return {
        driver => $driver_pkg->new(@args),
    };
}

sub DEMOLISH {
    $_[0]->done;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 Catmandu::Exporter - An exporter for bibliographic data structures.

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

=item each(\&callback)

Loops over all Perl objects in the stream and calls C<callback> on them. Returns the number of processed objects.

=item done()

Explicitly teardown the driver. This method is called at
C<DESTROY> time. Returns 1 or 0.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
