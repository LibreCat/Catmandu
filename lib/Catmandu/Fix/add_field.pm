package Catmandu::Fix::add_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is data_at);
use Moo;

has path  => (is => 'ro', required => 1);
has key   => (is => 'ro', required => 1);
has value => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $value) = @_;
    $path = [split /[\/\.]/, $path];
    my $key = $path->[-1];
    $orig->($class, path => $path, key => $key, value => $value);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $val = $self->value;
    my @matches = grep ref, data_at($self->path, $data, create => 1);
    for my $match (@matches) {
        if (is_array_ref($match)) {
            $match->[$key] = $val if is_natural($key);
        } else {
            $match->{$key} = $val;
        }
    }

    $data;
}

=head1 NAME

Catmandu::Fix::add_field - add or change the value of a HASH key

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
