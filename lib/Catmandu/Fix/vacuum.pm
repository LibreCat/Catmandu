package Catmandu::Fix::vacuum;

use Catmandu::Sane;
use Moo;
use CGI::Expand ();
use Catmandu::Fix::Has;

sub fix {
	my ($self,$data) = @_;
	my $ref = CGI::Expand->collapse_hash($data);

	for my $key (keys %$ref) {
		my $value = $ref->{$key};
		delete $ref->{$key} unless defined($value) && length $value && $value =~ /\S/; 
	}
	
	CGI::Expand->expand_hash($ref);
}

=head1 NAME

Catmandu::Fix::vacuum - delete all empty fields from your data

=head1 SYNOPSIS

   # Delete all the empty fields
   #
   # input:
   #
   # foo: ''
   # bar: []
   # relations: {}
   # test: 123
   #
   vacuum()
   
   # output:
   #
   # test: 123 
   #

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
