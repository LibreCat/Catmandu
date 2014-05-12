package Catmandu::Fix::sort_field;

use Catmandu::Sane;
use List::MoreUtils ();
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path    => (fix_arg => 1);
has uniq    => (fix_opt => 1);
has reverse => (fix_opt => 1);
has numeric => (fix_opt => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $comparer = $self->numeric ? "<=>" : "cmp";

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            my $perl = "if (is_array_ref(${var})) {";

            if ($self->uniq) {
                $perl .= "${var} = [List::MoreUtils::uniq(\@{${var}})];";
            }

            if ($self->reverse) {
                $perl .= "${var} = [sort { \$b $comparer \$a } \@{${var}}];";
            } else {
                $perl .= "${var} = [sort { \$a $comparer \$b } \@{${var}}];";
            }

            $perl .= "}";
            $perl;
        });
    });

}

=head1 NAME

Catmandu::Fix::sort_field - sort the values of an array

=head1 SYNOPSIS

   # e.g. tags => ["foo", "bar","bar"]
   sort_field('tags'); # tags =>  ["bar","bar","foo"]
   sort_field('tags',-uniq=>1); # tags =>  ["bar","foo"]
   sort_field('tags',-uniq=>1,-reverse=>1); # tags =>  ["foo","bar"]
   # e.g. nums => [ 100, 1 , 10]
   sort_field('nums',-numeric=>1); # nums => [ 1, 10, 100]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
