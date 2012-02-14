package Catmandu::Fix::split_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Moo;

has path       => (is => 'ro', required => 1);
has key        => (is => 'ro', required => 1);
has split_char => (is => 'ro', required => 1);
has guard      => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $path, $split_char) = @_;
    my ($p, $key, $guard) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, split_char => $split_char // qr'\s+', guard => $guard);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $guard = $self->guard;
    my $split_char = $self->split_char;
    for my $match (grep ref, data_at($self->path, $data)) {
        set_data($match, $key,
            map { $guard->($_) && is_value($_) ? [split $split_char, $_] : $_ }
                get_data($match, $key));
    }

    $data;
}

=head1 NAME

Catmandu::Fix::split_field - split a string value in a field into an ARRAY

=head1 SYNOPSIS

   # Split the 'foo' value into an array. E.g. foo => '1:2:3'
   split_field('foo',':'); # foo => [1,2,3]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
