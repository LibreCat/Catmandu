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
    my @old_matches = grep ref, data_at($self->old_path, $data, key => $old_key, guard  => $self->guard);
    my @new_matches = grep ref, data_at($self->new_path, $data, key => $new_key, create => 1);
    if (@old_matches == @new_matches) {
        for (my $i = 0; $i < @old_matches; $i++) {
            my $old_match = $old_matches[$i];
            my $new_match = $new_matches[$i];
            if (is_array_ref($new_match)) {
                is_integer($new_key) || next;
                if (is_array_ref($old_match)) {
                    next unless is_integer($old_key) && $old_key < @$old_match;
                    $new_match->[$new_key] = $old_match->[$old_key]; $old_match->[$old_key] = undef;
                } else {
                    $new_match->[$new_key] = delete $old_match->{$old_key};
                }
            } else {
                if (is_array_ref($old_match)) {
                    next unless is_integer($old_key) && $old_key < @$old_match;
                    $new_match->{$new_key} = $old_match->[$old_key]; $old_match->[$old_key] = undef;
                } else {
                    $new_match->{$new_key} = delete $old_match->{$old_key};
                }
            }
        }
        for my $match (@old_matches) {
            next unless is_array_ref($match);
            for (my $i = @$match; $i >= 0; --$i) {
                splice @$match, $i, 1 unless defined $match->[$i];
            }
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
