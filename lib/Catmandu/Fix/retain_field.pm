package Catmandu::Fix::retain_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is data_at);
use Moo;

has path => (is => 'ro', required => 1);
has key  => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    $path = [split /[\/\.]/, $path];
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
            if ($key < @$match) {
                splice @$match, 0, @$match, $match->[$key];
            } else {
                splice @$match;
            }
        } else {
            foreach (keys %$match) {
                delete $match->{$_} if $_ ne $key;
            }
        }
    }

    $data;
}

=head1 NAME

Catmandu::Fix::retain_field - delete everything from a field except 

=head1 SYNOPSIS

   # Delete every key from foo except bar
   retain_field('foo.bar');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
