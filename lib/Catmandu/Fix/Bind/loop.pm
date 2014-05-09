package Catmandu::Fix::Bind::loop;

use Moo;

with 'Catmandu::Fix::Bind';

has count => (is => 'ro' , default => sub { 1 } );
has index => (is => 'ro');
has promises => (is => 'rw', default => sub { [] });

sub bind {
   my ($self,$data,$code,$name) = @_;
   
   push @{$self->promises} , [$code,$name];

   $data;
}

sub finally {
	my ($self,$data) = @_;

    for (my $i = 0 ; $i < $self->count ; $i++) {

    	for my $promise (@{$self->promises}) {
    		my ($code,$name) = @$promise;
    		if (defined $self->index) {
   	  			$data->{$self->index} = $i;
   	  		}
	  	    $data = $code->($data);
    	}
    }

    if (defined $self->index) {
    	delete $data->{$self->index};
    }

    $self->promises([]);

    $data;
}

1;
