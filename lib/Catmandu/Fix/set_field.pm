package Catmandu::Fix::set_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Clone qw(clone);
use Moo;

has path  => (is => 'ro', required => 1);
has key   => (is => 'ro', required => 1);
has value => (is => 'ro', required => 1);
has guard => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $path, $value) = @_;
    my ($p, $key, $guard) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, value => $value, guard => $guard);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $val = $self->value;
    for my $match (grep ref, data_at($self->path, $data, key => $key, guard => $self->guard)) {
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

Catmandu::Fix::set_field - add or change the value of a HASH key or ARRAY index

=head1 DESCRIPTION

Contrary to C<add_field>, this will not create the intermediate structures
if they are missing.

=head1 SYNOPSIS

   # Change the value of 'foo' to 'bar 123'
   set_field('foo','bar 123');

   # Change a deeply nested key
   set_field('my.deep.nested.key','hi');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
