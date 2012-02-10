package Catmandu::Fix::copy_field;

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
    my @old_matches = grep ref, data_at($self->old_path, $data, key => $old_key, guard  => $self->guard);
    my @new_matches = grep ref, data_at($self->new_path, $data, key => $new_key, create => 1);

    if (@old_matches == @new_matches) {
        for (my $i = 0; $i < @old_matches; $i++) {
            set_data($new_matches[$i], $new_key,
                map { clone($_) }
                    get_data($old_matches[$i], $old_key));
        }
    }

    $data;
}

=head1 NAME

Catmandu::Fix::copy_field - copy the value of one field to a new field

=head1 SYNOPSIS

   # Copy the values of foo.bar into bar.foo
   copy_field('foo.bar','bar.foo');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
