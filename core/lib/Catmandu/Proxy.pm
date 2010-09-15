package Catmandu::Proxy::Role;

use Mouse::Role;

requires 'driver';
requires 'done';

sub BUILDARGS {
    my ($pkg, $driver_pkg, @args) = @_;

    $driver_pkg or confess "Driver is required";
    if ($driver_pkg !~ /::/) {
        $driver_pkg = join '::', $pkg, $driver_pkg;
    }
    eval { Mouse::Util::load_class($driver_pkg) } or
        confess "Can't load driver $driver_pkg";

    return {
        driver => $driver_pkg->new(@args),
    };
};

sub DEMOLISH {
    $_[0]->done;
}

package Catmandu::Proxy;

use Mouse ();
use Mouse::Exporter;

Mouse::Exporter->setup_import_methods(
    as_is => [ 'proxy' ],
    also  => 'Mouse',
);

sub proxy {
    my @methods = @_;
    my $pkg = caller;
    my $role_pkg = 'Catmandu::Proxy::Role';

    Carp::croak "A driver proxy can only be declared once"
        if Mouse::Util::does_role($pkg, $role_pkg);

    push @methods, 'done' unless grep /^done$/, @methods;

    $pkg->meta->add_attribute('driver', required => 1,
                                        handles  => [@methods],
                                        is       => 'ro');
    Mouse::Util::apply_all_roles($pkg, $role_pkg);
}

1;

