package Catmandu::Fix::add_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Clone qw(clone);
use Moo;

has path  => (is => 'ro', required => 1);
has key   => (is => 'ro', required => 1);
has value => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $value) = @_;
    my ($p, $key) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, value => $value);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $val = $self->value;
    for my $match (grep ref, data_at($self->path, $data, key => $key, create => 1)) {
        if ($key eq '*' && is_array_ref($match)) {
            for (my $i = 0; $i < @$match; $i++) {
                $match->[$i] = clone($val);
            }
        } else {
            set_data($match, $key, clone($val));
        }
    }

    $data;
}

=head1 NAME

Catmandu::Fix::add_field - add or change the value of a HASH key or ARRAY index

=head1 DESCRIPTION

Contrary to C<set_field>, this will create the intermediate structures
if they are missing.

=head1 SYNOPSIS

   # Add a new field 'foo' with value '2'
   add_field('foo','2');

   # Change the value of 'foo' to 'bar 123'
   add_field('foo','bar 123');

   # Create a deeply nested key
   add_field('my.deep.nested.key','hi');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
