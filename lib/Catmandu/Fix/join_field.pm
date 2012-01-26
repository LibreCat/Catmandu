package Catmandu::Fix::join_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is data_at);
use Moo;

has path      => (is => 'ro', required => 1);
has key       => (is => 'ro', required => 1);
has join_char => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $join_char) = @_;
    $path = [split /\./, $path];
    my $key = pop @$path;
    $orig->($class, path => $path, key => $key, join_char => $join_char // '');
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $join_char = $self->join_char;
    my @matches = grep ref, data_at($self->path, $data);
    for my $match (@matches) {
        if (is_array_ref($match)) {
            is_integer($key) || next;
            my $val = $match->[$key];
            $match->[$key] = join $join_char, @$val if is_array_ref($val);
        } else {
            my $val = $match->{$key};
            $match->{$key} = join $join_char, @$val if is_array_ref($val);
        }
    }

    $data;
}

=head1 NAME

Catmandu::Fix::join_field - join the ARRAY values of a field into a string

=head1 SYNOPSIS

   # Join the array values of a field into a string. E.g. foo => [1,2,3]
   join_field('foo','/'); # foo => "1/2/3"

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
