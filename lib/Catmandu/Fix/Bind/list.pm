package Catmandu::Fix::Bind::list;

use Moo;
use Data::Dumper;
use Catmandu::Util;

with 'Catmandu::Fix::Bind';

has path => (is => 'ro');

sub zero {
	my ($self) = @_;
	[];
}

sub unit {
	my ($self,$data) = @_;

	if (defined $self->path) {
		Catmandu::Util::data_at($self->path,$data);
	}
	elsif (Catmandu::Util::is_array_ref($data)) {
		$data;
	}
	else {
		[$data];
	}	
}

sub bind {
	my ($self,$mvar,$func,$name) = @_;

	if (Catmandu::Util::is_array_ref($mvar)) {
		[ map { $func->($_) } @$mvar ];
	}
	else {
		return $self->zero;
	}
}

# Flatten an array: [ [A] , [A] , [A] ] -> [ A, A, A ]
sub plus {
	my ($self,$prev,$next) = @_;

	Catmandu::Util::is_array_ref($next) ? [ $prev, @$next ] : [ $prev, $next] ;
}

=head1 NAME

Catmandu::Fix::Bind::list - a binder that computes Fix-es for every element in a list

=head1 SYNOPSIS

 add_field(demo.$append.test,1)
 add_field(demo.$append.test,2)

 do list(path => demo)
	add_field(foo,bar)
 end

 # will produce
   demo:
   	 - test: 1
   	   foo: bar
   	 - test: 2
   	   foo: bar

=head1 DESCRIPTION

The list binder will iterate over all the elements in a list and fixes the values in context of that list.

=head1 CONFIGURATION

=head2 path 

The path to a list in the data.

=head1 AUTHOR

Patrick Hochstenbach - L<Patrick.Hochstenbach@UGent.be>

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut

1;