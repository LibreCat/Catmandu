package Catmandu::Fix::Bind::identity;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo;
use namespace::clean;

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

1;

__END__

=pod

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

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
