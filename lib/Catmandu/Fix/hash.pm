package Catmandu::Fix::hash;

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

            "if (is_array_ref(${var})) {" .
                "${var} = {\@{${var}}};" .
            "}";
        });
    });

}

=head1 NAME

Catmandu::Fix::hash - creates a hash out of an array

=head1 SYNOPSIS

   # tags => ['name', 'Peter', 'age', 12]
   hash('tags');
   # tags => {name => 'Peter', age => 12}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
