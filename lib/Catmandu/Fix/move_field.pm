package Catmandu::Fix::move_field;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo;
use Catmandu::Util qw(as_path);
use Clone qw(clone);
use namespace::clean;
use Catmandu::Fix::Has;

has old_path => (fix_arg => 1, coerce => \&as_path);
has new_path => (fix_arg => 1, coerce => \&as_path);
has getter => (is => 'lazy');
has deleter => (is => 'lazy');
has creator => (is => 'lazy');

sub _build_getter {
    my ($self) = @_;
    $self->old_path->getter;
}

sub _build_deleter {
    my ($self) = @_;
    $self->old_path->deleter;
}

sub _build_creator {
    my ($self) = @_;
    $self->new_path->creator;
}

sub fix {
    my ($self, $data) = @_;
    my $vals = [map {clone($_)} @{$self->getter->($data)}];
    $self->deleter->($data);
    while (@$vals) {
        $self->creator->($data, shift @$vals);
    }
    $data;
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
