package Catmandu::Fix::Bind::each;

use Moo;
use Catmandu::Util qw(:data :is);
use Data::Dumper;

with 'Catmandu::Fix::Bind';

has path  => (is => 'ro' , required => 1);
has index => (is => 'ro');

sub bind {
	my ($self,$data,$code,$name) = @_;

	my $value = data_at($self->path,$data);

	if (defined $value && is_array_ref($value)) {
		for my $i (@$value) {
			$data->{$self->index} = $i if defined $self->index;
			$data = $code->($data);
		}
	}

	$data;
}

1;
