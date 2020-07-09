package Catmandu::Fix::move_field;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Clone qw(clone);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has old_path => (fix_arg => 1);
has new_path => (fix_arg => 1);

sub _build_fixer {
    my ($self)   = @_;
    my $old_path = as_path($self->old_path);
    my $new_path = as_path($self->new_path);
    my $getter   = $old_path->getter;
    my $deleter  = $old_path->deleter;
    my $creator  = $new_path->creator;

    sub {
        my $data   = $_[0];
        my $values = [map {clone($_)} @{$getter->($data)}];
        $deleter->($data);
        while (@$values) {
            $data = $creator->($data, shift @$values);
        }
        $data;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::move_field - move a field to another place in the data structure

=head1 SYNOPSIS

   # Move single fields

   # Move 'foo.bar' to 'bar.foo'
   move_field(foo.bar, bar.foo)

   # Move multipe fields
   # Data:
   # a:
   #   b: test1
   #   c: test2
   move_field(a,z)  # -> Move all the 'a' to 'z'
                    # z:
                    #   b: test1
                    #   c: test2
   # Data:
   # a:
   #   b: test1
   #   c: test2
   move_field(a,.)  # -> Move the fields 'b' and 'c' to the root
                    # b: test1
                    # c: test2

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
