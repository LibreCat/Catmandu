package Catmandu::Fix::move_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Clone qw(clone);
use Moo;

has old_path => (is => 'ro', required => 1);
has old_key  => (is => 'ro', required => 1);
has new_path => (is => 'ro', required => 1);
has new_key  => (is => 'ro', required => 1);
has guard    => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $old_path, $new_path) = @_;
    my ($old_p, $old_key, $guard) = parse_data_path($old_path);
    my ($new_p, $new_key) = parse_data_path($new_path);
    $orig->($class, old_path => $old_p, old_key => $old_key,
                    new_path => $new_p, new_key => $new_key,
                    guard => $guard);
};

sub fix {
    my ($self, $data) = @_;

    my $old_path = $self->old_path;
    my $old_key  = $self->old_key;
    my $new_path = $self->new_path;
    my $new_key  = $self->new_key;
    my $guard = $self->guard;
    my @old_matches = grep ref, data_at($self->old_path, $data);
    my @new_matches = grep ref, data_at($self->new_path, $data, key => $new_key, create => 1);
    if (@old_matches == @new_matches) {
        for (my $i = 0; $i < @old_matches; $i++) {
            set_data($new_matches[$i], $new_key,
                delete_data($old_matches[$i], $old_key, $guard));
        }

    }

    $data;
}

=head1 NAME

Catmandu::Fix::move_field - move a field to another place in the data structure

=head1 SYNOPSIS

   # Move 'foo.bar' to 'bar.foo'
   move_field('foo.bar','bar.foo');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
