package Catmandu::Fix::Bind::Group;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Moo::Role;
use namespace::clean;

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Bind::Group - a role for a binder that executes all fixes as one group

=head1 SYNOPSIS

    # Fixes fix1(), ... fixN() will be passed as one function to the internal 'bind' method
	do identity()
	   fix1()
	   .
	   .
	   fixN()
	end

    # Fixes fix1(), ... fixN() will be passed as one by one to the internal 'bind' method
    do maybe()
       fix1()
       .
       .
       fixN()
    end

=head1 DESCRIPTION

This role flags a L<Catmandu::Fix::Bind> implementation as a L<Catmandu::Fix::Bind::Group>.
All fixes inside a Bind will be treated as one singular function.

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
