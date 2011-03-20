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
  while(1) {
     $cnt++;
 
     # Create a hash and send it to the callback
     $sub->({ msg => "$cnt: Hello importer"});

     if ($cnt % 1000 == 0) {
	sleep int(rand(3) + 1);
     } 
  }
  
  # Return the number of objects created
  $cnt;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
