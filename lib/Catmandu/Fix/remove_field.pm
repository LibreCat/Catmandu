package Catmandu::Fix::remove_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Moo;

has path => (is => 'ro', required => 1);
has key  => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    my ($p, $key) = parse_data_path($path);
    $orig->($class, path => $p, key => $key);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    for my $match (grep ref, data_at($self->path, $data)) {
        delete_data($match, $key);
    }

    $data;
}

=head1 NAME

Catmandu::Fix::remove_field - remove a field form the data

=head1 SYNOPSIS

   # Remove the foo.bar field
   remove_field('foo.bar');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
