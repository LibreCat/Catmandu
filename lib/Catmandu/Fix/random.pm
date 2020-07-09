package Catmandu::Fix::random;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Util::Path qw(as_path);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);
has max  => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    my $max = $self->max;
    as_path($self->path)->creator(sub {int(rand($max))});
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::random - create an random number in a field

=head1 SYNOPSIS

   # Add a new field 'foo' with a random value between 0 and 9
   random(foo, 10)

   # Add a new field 'my.random.number' with a random value 0 or 1
   random(my.random.number,2)
   
=head1 SEE ALSO

L<Catmandu::Fix>

=cut
