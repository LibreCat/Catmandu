package Catmandu::Fix::Condition::all_match;

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
            my $perl = $self->invert ? "if (" : "unless (";
            $perl .= "${var} =~ /${search}/";
            $perl .= ") {";
            $perl .= "last $label;";
            $perl .= "}";
            for my $fix (@{$self->fixes}) {
                $perl .= $fixer->emit_fix($fix);
            }
            $perl;
        });
    });
}

=head1 NAME

Catmandu::Fix::Condition::all_match - only execute fixes if all path values match the given regex

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if all members of 'oogly' have the value 'doogly'
   if_all_match('oogly.*', 'doogly');
   upcase('foo'); # foo => 'BAR'
   end()

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
