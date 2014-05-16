package Catmandu::Fix::Bind::identity;

use Moo;

with 'Catmandu::Fix::Bind';

=head1 NAME

Catmandu::Fix::Bind::identity - a binder that doesn't influence computation

=head1 SYNOPSIS

	do identity()
	   fix1()
	   fix2()
	   fix3()
	   .
	   .
	   .
	   fixN()
	end

	# will have the same (side)effects as

	fix1()
	fix2()
	fix3()
	.
	.
	.
	fixN()

=head1 DESCRIPTION

The identity binder doesn't embody any computational strategy. It simply 
applies the bound fix functions to its input without any modification.

=head1 AUTHOR

Patrick Hochstenbach - L<Patrick.Hochstenbach@UGent.be>

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut

1;