package Catmandu::Fix::Condition::exists;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Condition';

has path => (fix_arg => 1);

sub emit {
    my ($self, $fixer, $label) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $str_key = $fixer->emit_string($key);

    my $perl = $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var  = shift;
        my $perl = "if (";
        if ($key eq '$first' || $key eq '$last') {
            $perl .= "is_array_ref(${var}) && \@{${var}}";
        } elsif ($key =~ /^\d+$/) {
            $perl .= "is_hash_ref(${var}) && exists(${var}->{${str_key}}) || is_array_ref(${var}) && \@{${var}} > ${key}";
        } else {
            $perl .= "is_hash_ref(${var}) && exists(${var}->{${str_key}})";
        }
        $perl .= ") {";

        $perl .= $fixer->emit_fixes($self->pass_fixes);

        $perl .= "last $label;";
        $perl .= "}";
        $perl;
    });

    $perl .= $fixer->emit_fixes($self->fail_fixes);

    $perl;
}

=head1 NAME

Catmandu::Fix::Condition::exists - only execute fixes if the path exists

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if the field 'oogly' exists
   if exists(oogly)
     upcase(foo) # foo => 'BAR'
   end
   # inverted
   unless exists(oogly)
     upcase(foo) # foo => 'bar'
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
