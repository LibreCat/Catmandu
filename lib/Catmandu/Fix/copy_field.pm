package Catmandu::Fix::copy_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is data_at);
use Moo;

has old_path => (is => 'ro', required => 1);
has old_key  => (is => 'ro', required => 1);
has new_path => (is => 'ro', required => 1);
has new_key  => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $old_path, $new_path) = @_;
    $old_path = [split /[\/\.]/, $old_path];
    $new_path = [split /[\/\.]/, $new_path];
    my $old_key = pop @$old_path;
    my $new_key = pop @$new_path;
    $orig->($class, old_path => $old_path, old_key => $old_key,
                    new_path => $new_path, new_key => $new_key);
};

sub fix {
    my ($self, $data) = @_;

    my $old_path = $self->old_path;
    my $old_key  = $self->old_key;
    my $new_path = $self->new_path;
    my $new_key  = $self->new_key;
    my @old_matches = grep ref, data_at($self->old_path, $data);
    my @new_matches = grep ref, data_at($self->new_path, $data, create=>1);
    if (@old_matches == @new_matches) {
        for (my $i = 0; $i < @old_matches; $i++) {
            my $old_match = $old_matches[$i];
            my $new_match = $new_matches[$i];
            if (is_array_ref($new_match)) {
                is_integer($new_key) || next;
                if (is_array_ref($old_match)) {
                    next unless is_integer($old_key) && $old_key < @$old_match;
                    $new_match->[$new_key] = $old_match->[$old_key];
                } else {
                    $new_match->[$new_key] = $old_match->{$old_key};
                }
            } else {
                if (is_array_ref($old_match)) {
                    next unless is_integer($old_key) && $old_key < @$old_match;
                    $new_match->{$new_key} = $old_match->[$old_key];
                } else {
                    $new_match->{$new_key} = $old_match->{$old_key};
                }
            }
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
