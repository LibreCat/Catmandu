package Catmandu::Fix::Condition::any_match;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Fix::Condition';

has path   => (is => 'ro', required => 1);
has search => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $search) = @_;
    $orig->($class, path => $path, search => $search);
};

sub emit {
    my ($self, $fixer, $label) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $str_key = $fixer->emit_string($key);
    my $search = $self->search;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var  = shift;
            my $perl = $self->invert ? "unless (" : "if (";
            $perl .= "${var} =~ /${search}/";
            $perl .= ") {";
            for my $fix (@{$self->fixes}) {
                $perl .= $fixer->emit_fix($fix);
            }
            $perl .= "last $label;";
            $perl .= "}";
            $perl;
        });
    });
}

=head1 NAME

Catmandu::Fix::Condition::any_match - only execute fixes if any path value matches the given regex

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if field 'oogly' has the value 'doogly'
   if_any_match('oogly', 'doogly');
   upcase('foo'); # foo => 'BAR'
   end()

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
