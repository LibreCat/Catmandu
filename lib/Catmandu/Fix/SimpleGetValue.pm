package Catmandu::Fix::SimpleGetValue;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Moo::Role;
use namespace::clean;

with 'Catmandu::Fix::Base';

requires 'path';
requires 'emit_value';

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key  = pop @$path;

    $fixer->emit_walk_path(
        $fixer->var,
        $path,
        sub {
            my $var = shift;
            $fixer->emit_get_key(
                $var, $key,
                sub {
                    my $var = shift;
                    $self->emit_value($var, $fixer);
                }
            );
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::SimpleGetValue - helper class for creating emit Fix-es

=head1 SYNOPSIS

    # Create a Rot13 encrypter

    package Catmandu::Fix::rot13;

    use Catmandu::Sane;
    use Moo;
    use Catmandu::Fix::Has;

    has path => (fix_arg => 1);

    with 'Catmandu::Fix::SimpleGetValue';

    sub emit_value {
        my ($self, $var, $fixer) = @_;
        "${var} =~ y/A-Za-z/N-ZA-Mn-za-m/ if is_string(${var});";
    }

    # Now you can use this Fix in your scripts
    rot13(my.deep.nested.path)
    rot13(authors.*)

=head1 DESCRIPTION

Catmandu::Fix::SimpleGetValue eases the creation of emit Fixes that transform
values on a JSON path. A Fix package implementing Catmandu::Fix::SimpleGetValue
needs to implement a method C<emit_value> which accepts the variable name on
which the Fix operates and an instance of Catmandu::Fixer. The method should
return a string containing the Perl code to transform values on a JSON path.

It is not possible to inspect in an emit Fix the actual value on which this Fix
runs: $var contains a variable name not the actual value. The real values are
only available at run time. Emit Fixes are used to compile Perl code into Fix
modules which do the actual transformation.

For more examples look at the source code of:

=over 4

=item Catmandu::Fix::append;

=item Catmandu::Fix::replace_all

=item Catmandu::Fix::upcase

=back

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
