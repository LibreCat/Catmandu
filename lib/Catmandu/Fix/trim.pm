package Catmandu::Fix::trim;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Fix::Base';

has path => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    $orig->($class, path => $path);
};

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "${var} = trim(${var}) if is_string(${var});";
        });
    });
}

=head1 NAME

Catmandu::Fix::trim - trim the value of a field from leading and ending spaces

=head1 SYNOPSIS

   # Trim 'foo'. E.g. foo => '   abc   ';
   trim('foo'); # foo => 'abc';

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
