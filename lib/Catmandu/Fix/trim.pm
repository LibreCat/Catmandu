package Catmandu::Fix::trim;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data trim);
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
            map { $guard->($_) && is_string($_) ? trim($_) : $_ }
                get_data($match, $key));
    }

    $data;
}

=head1 NAME

Catmandu::Fix::trim - trim the value of a field from leading and ending spaces

=head1 SYNOPSIS

   # Trim 'foo'. E.g. foo => '   abc   ';
   trim('foo'); # foo => 'abc';

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
