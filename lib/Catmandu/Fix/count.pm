package Catmandu::Fix::count;

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
                "${var} = scalar \@{${var}};" .
            "} elsif (is_hash_ref(${var})) {" .
                "${var} = scalar keys \%{${var}};" .
            "}";
        });
    });
}

=head1 NAME

Catmandu::Fix::count - replace the value of an array or hash field with it's count

=head1 SYNOPSIS

   # e.g. tags => ["foo", "bar"]
   count('tags'); # tags => 2

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
