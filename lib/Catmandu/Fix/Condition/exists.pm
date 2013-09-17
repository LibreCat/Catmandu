package Catmandu::Fix::Condition::exists;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Fix::Condition';

has path => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    $orig->($class, path => $path);
};

sub emit {
    my ($self, $fixer, $label) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $str_key = $fixer->emit_string($key);

    my $perl = $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var  = shift;
        my $perl = "if (";
        if ($key =~ /^\d+$/) {
            $perl .= "is_hash_ref(${var}) && exists(${var}->{${str_key}}) || is_array_ref(${var}) && \@{${var}} > ${key}";
        } else {
            $perl .= "is_hash_ref(${var}) && exists(${var}->{${str_key}})";
        }
        $perl .= ") {";
        for my $fix (@{$self->fixes}) {
            $perl .= $fixer->emit_fix($fix);
        }
        $perl .= "last $label;";
        $perl .= "}";
        $perl;
    });

    for my $fix (@{$self->otherwise_fixes}) {
        $perl .= $fixer->emit_fix($fix);
    }
    $perl;
}

=head1 NAME

Catmandu::Fix::Condition::exists - only execute fixes if the path exists

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if the field 'oogly' exists
   if_exists('oogly');
   upcase('foo'); # foo => 'BAR'
   end()
   # inverted
   unless_exists('oogly');
   upcase('foo'); # foo => 'bar'
   end()

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
