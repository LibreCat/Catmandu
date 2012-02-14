package Catmandu::Fix::capitalize;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data as_utf8);
use Moo;

has path  => (is => 'ro', required => 1);
has key   => (is => 'ro', required => 1);
has guard => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    my ($p, $key, $guard) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, guard => $guard);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $guard = $self->guard;
    for my $match (grep ref, data_at($self->path, $data)) {
        set_data($match, $key,
            map { $guard->($_) && is_string($_) ? ucfirst(lc(as_utf8($_))) : $_ }
                get_data($match, $key));
    }

    $data;
}

=head1 NAME

Catmandu::Fix::capitalize - capitalize the value of a key

=head1 SYNOPSIS

   # Capitalize the value of foo. E.g. foo => 'bar'
   capitalize('foo');  # foo => 'Bar'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
