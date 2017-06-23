package Catmandu::Fix::clone;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use namespace::clean;

with 'Catmandu::Fix::Base';

sub emit {
    my ($self, $fixer) = @_;
    $fixer->emit_clone($fixer->var);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::clone - create a clone of the data object

=head1 SYNOPSIS

   # Create a clone of the data object
   clone()

   # Now do all the changes on the clone
   add_field(foo, 2)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
