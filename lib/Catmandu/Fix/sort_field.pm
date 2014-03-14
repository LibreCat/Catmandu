package Catmandu::Fix::sort_field;

use Catmandu::Sane;
use Moo;
use List::MoreUtils;

with 'Catmandu::Fix::Base';

has path => (is => 'ro', required => 1);
has uniq => (is => 'ro', required => 1);
has reverse => (is => 'ro');
has numeric => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $path, %options) = @_;
    my $uniq = defined $options{-uniq} && $options{-uniq} == 1 ? 1 : 0;
    my $reverse = defined $options{-reverse} && $options{-reverse} == 1 ? 1 : 0;
    my $numeric = defined $options{-numeric} && $options{-numeric} == 1 ? 1 : 0;
    $orig->($class, path => $path , uniq => $uniq , reverse => $reverse , numeric => $numeric);
};

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $comparer = $self->numeric ? "<=>" : "cmp";

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            my $perl = "";

            if ($self->uniq) {
                $perl .= "if (is_array_ref(${var})) {" .
                    "${var} = [List::MoreUtils::uniq \@{${var}}];" .
                "}";
            }

            if ($self->reverse) {
                $perl .= "if (is_array_ref(${var})) {" .
                    "${var} = [sort { \$b $comparer \$a } \@{${var}}];" .
                "}";
            }
            else {
                $perl .= "if (is_array_ref(${var})) {" .
                    "${var} = [sort { \$a $comparer \$b } \@{${var}}];" .
                "}";
            }

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