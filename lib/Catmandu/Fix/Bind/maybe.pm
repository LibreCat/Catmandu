package Catmandu::Fix::Bind::maybe;

use Moo;
use Data::Dumper;

with 'Catmandu::Fix::Bind';

sub bind {
	my ($self,$mvar,$func) = @_;

	my $res;

	eval {
		$res = $func->($mvar);
	};
	if ($@) {
		return $mvar;
	}
	
	$res;
}

=head1 NAME

Catmandu::Fix::Bind::maybe - a binder that ignores all Fix functions that throw errors

=head1 SYNOPSIS

 do maybe()
	foo()
	throw_error() # will be ignored
	bar()
 end

=head1 DESCRIPTION

The maybe binder computes all the Fix function and ignores fixes that throw exceptions.

=head1 AUTHOR

hochsten L<hochsten@cpan.org>

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut

1;