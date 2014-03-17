package Catmandu::Fix::hash;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Fix::Base';

has path   => (is => 'ro', required => 1);
has invert => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $path, %options) = @_;
    my $invert = defined $options{-invert} && $options{-invert} == 1 ? 1 : 0;
    $orig->($class, path => $path, invert => $invert);
};

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;

            if ($self->invert) {
                "if (is_hash_ref(${var})) {" .
                    "${var} = [ \%{${var}} ];" .
                "}";
            }
            else {
                "if (is_array_ref(${var})) {" .
                    "${var} = { \@{${var}} };" .
                "}";
            }
        });
    });

}

=head1 NAME

Catmandu::Fix::hash - creates a hash out of an array

=head1 SYNOPSIS

   # e.g. tags => ["name", "Peter","age", 12]
   hash('tags'); # tags =>  { name => 'Peter' , age => 12 }

   # invert the action (order is not preserved)
   hash('tags', -invert => 1); # tags => ["name", "Peter","age", 12]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;