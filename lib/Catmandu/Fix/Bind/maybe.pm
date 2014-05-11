package Catmandu::Fix::Bind::maybe;

use Moo;
use Data::Dumper;

with 'Catmandu::Fix::Bind';

sub bind {
	my ($self,$mvar,$func) = @_;

	if (! defined $mvar) {
		return undef;
	}

	my $res = $func->($mvar);
	
	$res;
}

=head1 NAME

Catmandu::Fix::Bind::maybe - a binder that skips fixes is one returns undef

=head1 SYNOPSIS

 do maybe()
	foo()
	return_undef() # rest will be ignored
	bar()
 end

=head1 DESCRIPTION

The maybe binder computes all the Fix function and ignores fixes that throw exceptions.

=head1 AUTHOR

Patrick Hochstenbach <Patrick . Hochstenbach @ UGent . be >

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut

1;