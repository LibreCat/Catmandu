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

=head1 NAME

Catmandu::Fix::Bind::each - loop over all the values in a path

=head1 SYNOPSIS

   add_field(demo.$append,foo)
   add_field(demo.$append,bar)

   do each(path => demo, index => val)
        copy_field(val,demo2.$append)
   end

   # demo  = ['foo' , 'bar'];
   # demo2 = ['foo' , 'bar'];

=head1 PARAMETERS

=head2 path (required)

A path to an array ref over which the 'each' needs to loop

=head2 index (optional)

The name of an index field that gets populated for every value on the path

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut

1;
