package Catmandu::Fix::downcase;

use Catmandu::Sane;
use Catmandu::Util qw(:is data_at as_utf8);
use Moo;

has path => (is => 'ro', required => 1);
has key  => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    $path = [split /\./, $path];
    my $key = pop @$path;
    $orig->($class, path => $path, key => $key);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my @matches = grep ref, data_at($self->path, $data);
    for my $match (@matches) {
        if (is_array_ref($match)) {
            is_integer($key) || next;
            my $val = $match->[$key];
            $match->[$key] = lc as_utf8 $val if is_string($val);
        } else {
            my $val = $match->{$key};
            $match->{$key} = lc as_utf8 $val if is_string($val);
        }
    }

    $data;
}

=head1 NAME

Catmandu::Fix::downcase - lowercase the value of a field

=head1 SYNOPSIS

   # Lowercase 'foo'. E.g. foo => 'BAR'
   downcase('foo'); # foo => 'bar'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
