package Catmandu::Fix::add_field;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo;
use Catmandu::Util qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1, coerce => \&as_path);
has value => (fix_arg => 1, default => sub {undef;});
has creator => (is => 'lazy');

sub _build_creator {
    my ($self) = @_;
    $self->path->creator(value => $self->value);
}

sub fix {
    $_[0]->creator->($_[1]);
    $_[1];
}

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $value
        = defined $self->value ? $fixer->emit_value($self->value) : 'undef';

    $fixer->emit_create_path(
        $fixer->var,
        $path,
        sub {
            my $var = shift;
            "${var} = ${value};";
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::add_field - add or change the value of a HASH key or ARRAY index

=head1 DESCRIPTION

Contrary to C<set_field>, this will create the intermediate structures
if they are missing.

=head1 SYNOPSIS

   # Add a new field 'foo' with value 2
   add_field(foo, 2)

   # Change the value of 'foo' to 'bar 123'
   add_field(foo, 'bar 123')

   # Create a deeply nested key
   add_field(my.deep.nested.key, hi)

   # If the second argument is omitted the field has a null value
   add_field(foo)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
