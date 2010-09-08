package Catmandu::Importer::Factory;

use Carp;

sub open {
  my ($pkg,$store,$file,%args) = @_;

  my $driver_class = "Catmandu::Importer::$store";

  eval qq{
          require $driver_class
  };

  if ($@) {
    Carp::croak("Failed to load driver '$driver_class'");
  }

  my $inst = eval { $driver_class->open($file,%args) };

  unless ($inst && !$@) {
    Carp::croak("$driver_class initialisation failed : $@");
  }  

  return $inst;
}

1;

__END__

=head1 NAME

 Catmandu::Importer::Factory - Catmandu::Importer factory

=head1 SYNOPSIS

 use Catmandu::Importer::Factory;

 my $importer = Catmandu::Importer::Factory->open('Mods',$file);

 my $count = $importer->each(sub {
   # $obj process
 });

 $importer->close();

=head1 METHODS

=over 4

=item open($driver,$file,%args) 

Load a Catmandu::Importer driver and instantiate it with the $file. Returns the Catmandu::Importer on success undef on failure.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
