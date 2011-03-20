package Catmandu::Importer::Custom;
use Moose;

with qw(
  Catmandu::Importer
);

sub default_attribute {}

sub each {
  my ($self, $sub) = @_;

  # Your loop..
  my $cnt = 0;
  for $cnt (1..10) {
     
     # Create a hash and send it to the callback
     $sub->({ msg => "$cnt: Hello importer"});
  }
  
  # Return the number of objects created
  $cnt;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
