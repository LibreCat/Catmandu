package Catmandu::Fix::Condition::SimpleAnyTest;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo::Role;
use namespace::clean;

with 'Catmandu::Fix::Condition';

requires 'path';
requires 'emit_test';

sub emit {
    my ($self, $fixer, $label) = @_;
    my $path = $fixer->split_path($self->path);
    my $key  = pop @$path;

    my $perl = $fixer->emit_walk_path(
        $fixer->var,
        $path,
        sub {
            my $var = shift;
            $fixer->emit_get_key(
                $var, $key,
                sub {
                    my $var = shift;
                    my $perl
                        = "if (" . $self->emit_test($var, $fixer) . ") {";

                    $perl .= $fixer->emit_fixes($self->pass_fixes);

                    $perl .= "last $label;";
                    $perl .= "}";
                    $perl;
                }
            );
        }
    );

    $perl .= $fixer->emit_fixes($self->fail_fixes);

    $perl;
}

1;

__END__

=pod;

=head1 NAME

Catmandu::Fix::Condition::SimpleAllTest - Base class to ease the construction of any match conditionals

=head1 SYNOPSIS

   package Catmandu::Fix::Condition::has_even

   use Catmandu::Sane;
   use Moo;
   use Catmandu::Fix::Has;

   has path    => (fix_arg => 1);

   with 'Catmandu::Fix::Condition::SimpleAnyTest';
 
   sub emit_test {
       my ($self, $var) = @_;
       my $value = $self->value;
       "is_value(${var}) && ${var} % 2 == 0";
   }

   1;

   # Now you can write in your fixes
   has_even('my_field')    # True when my_field is 0,2,4,6,...
   has_even('my_field.*')  # True when at least one my_field is 0,2,4,6,...

=head1 DESCRIPTION

The is a base class to ease the construction of Catmandu::Fix::Conditional-s. An 'any' test matches
when at least one node on a path match a condition. E.g.

   any_match('title','abc')    # true when the title field contains 'abc'

   any_match('title.*','abc')  # true when at least one title fields contain 'abc'

=head1 SEE ALSO

L<Catmandu::Fix::Condition::any_match>

=cut
