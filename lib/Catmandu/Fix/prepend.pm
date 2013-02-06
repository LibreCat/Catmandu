package Catmandu::Fix::prepend;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Moo;

has path => (is => 'ro', required => 1);
has key  => (is => 'ro', required => 1);
has val  => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $val) = @_;
    my ($p, $key) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, val => $val);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $val = $self->val;
    for my $match (grep ref, data_at($self->path, $data)) {
        set_data($match, $key,
            map { is_value($_) ? "$val$_" : $_ }
                get_data($match, $key));
    }

    $data;
}

=head1 NAME

Catmandu::Fix::prepend - add a prefix to the value of a field

=head1 SYNOPSIS

   # prepend the value of 'foo'. E.g. foo => 'bar'
   prepend('foo', 'foo'); # foo => 'foobar'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
