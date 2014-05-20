package Catmandu::Fix::Condition::less_than;
use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Condition';

has path    => (fix_arg => 1);
has value   => (fix_arg => 1);

sub emit {
    my ($self, $fixer, $label) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $str_key = $fixer->emit_string($key);
    my $value = $fixer->emit_string($self->value);

    my $perl = $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var  = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "if (is_value(${var}) && ${var} < $value) {" .
            $fixer->emit_fixes($self->pass_fixes) .
            "last $label;" .
            "}";
        });
    });

    $perl .= $fixer->emit_fixes($self->fail_fixes);

    $perl;
}

=head1 NAME

Catmandu::Fix::Condition::less_than - Excute fixes when a field is less than a value

=head1 SYNOPSIS

   # less_than(X,Y) is true when X < Y
   if less_than('year','2018')
   	add_field('my.funny.title','true')
   end

=head1 SEE ALSO

L<Catmandu::Fix::Condition::greater_than>

=cut

1;