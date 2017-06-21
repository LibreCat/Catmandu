package Catmandu::Fix::random;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path => (fix_arg => 1);
has max  => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $max  = $fixer->emit_value($self->max);

    $fixer->emit_create_path(
        $fixer->var,
        $path,
        sub {
            my $var = shift;
            "${var} = int(rand(${max}));";
        }
    );
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
