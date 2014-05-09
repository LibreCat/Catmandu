package Catmandu::Fix::Bind::each;

use Moo;
use Catmandu::Util qw(:data :is);

with 'Catmandu::Fix::Bind';

has path     => (is => 'ro' , required => 1);
has index    => (is => 'ro');
has values   => (is => 'rw', default => sub { [] });
has promises => (is => 'rw', default => sub { [] });

sub bind {
	my ($self,$data,$code,$name) = @_;

	my $value = data_at($self->path,$data);

	if (defined $value && is_array_ref($value)) {
		$self->values($value);
		push @{$self->promises} , [$code,$name];
	}

	$data;
}

sub finally {
	my ($self,$data) = @_;

    for my $i (@{$self->values}) {
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
    $self->values([]);

    $data;
}

1;
