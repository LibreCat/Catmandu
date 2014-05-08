package Catmandu::Fix::Bind::loop;

use Moo;

with 'Catmandu::Fix::Bind';

has count => (is => 'ro' , default => sub { 1 } );
has index => (is => 'ro');

sub bind {
   my ($self,$data,$code,$name) = @_;
   
   for (my $i = 0 ; $i < $self->count ; $i++) {
   	  if (defined $self->index) {
   	  	$data->{$self->index} = $i;
   	  }
	  $data = $code->($data);
   }

   $data;
}

1;
