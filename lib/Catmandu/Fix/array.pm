package Catmandu::Fix::array;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;

            "if (is_hash_ref(${var})) {" .
                "${var} = [\%{${var}}];" .
            "}";
        });
    });

}

=head1 NAME

Catmandu::Fix::array - creates an array out of a hash

=head1 SYNOPSIS

   # tags => {name => 'Peter', age => 12}
   array('tags');
   # tags => ['name', 'Peter', 'age', 12]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;

