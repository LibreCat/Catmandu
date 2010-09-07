package Catmandu::Store::Factory;

use Carp;

sub connect {
  my ($pkg,$store,%args) = @_;

  my $driver_class = "Catmandu::Store::$store";

  eval qq{
          require $driver_class
  };

  if ($@) {
    Carp::croak("Failed to load driver '$driver_class'");
  }

  my $inst = eval { $driver_class->connect(%args) };

  unless ($inst && !$@) {
    Carp::croak("$driver_class initialisation failed : $@");
  }  

  return $inst;
}

1;

__END__

=head1 NAME

 Catmandu::Store::Factory - Catmandu::Store factory

=head1 SYNOPSIS

 use Catmandu::Store::Factory;

 $store = Catmandu::Store::Factory->connect('Mock',file => '/tmp/test.db');

 $store->load(..);
 $store->save(..);
 $store->delete(..);

=head1 METHODS

=over 4

=item connect($driver,%args);

Create a Catmandu::Store object. Returns a Catmandu::Store or undef on failure.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
