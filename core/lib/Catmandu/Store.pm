package Catmandu::Store;

use Mouse;

has 'driver' => (is => 'ro', required => 1, handles => [qw(load save delete each done)]);

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

 Catmandu::Store - An store for bibliographic data structures.

=head1 SYNOPSIS

 $store = Catmandu::Store->new('Mock', file => $file);
 $obj = { 'title' => 'Catmandu' };
 $obj = $store->save($obj); # $obj = { '_id' => '1271-23138230-AEF12781' , 'name' => 'Catmandu' };
 $obj = $store->load('1271-23138230-AEF12781');

 $store->delete($obj);

 $store->each(sub {
    say $_[0]->{'name'};
 });

 $store->done;

=head1 METHODS

=over 4

=item new($driver_pkg, @args);

Constructs a new store client. Passes @args to the driver instance.
C<$driver_pkg> is assumed to live in the Catmandu::Store
namespace unless full a package name is given.

=item driver()

Returns the underlying driver.

=item load($id)

Retrieve the object with the key C<$id> form the store. Returns
the object as a hashref when found, C<undef> otherwise.

=item save($obj);

Save C<$obj> in the store. Returns the object as a hashref
when found, C<undef> otherwise.

=item delete($obj);

Delete C<$obj> from the store. Returns 1 or 0.

=item each(\%callback);

Loops over all objects in the store and passes them to C<callback>. Returns the number of objects found.

=item done()

Explicitly teardown the driver. This method is called at
C<DESTROY> time. Returns 1 or 0.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
