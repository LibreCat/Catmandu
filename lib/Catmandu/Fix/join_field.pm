package Catmandu::Fix::join_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Moo;

has path      => (is => 'ro', required => 1);
has key       => (is => 'ro', required => 1);
has join_char => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $join_char) = @_;
    my ($p, $key) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, join_char => $join_char // '');
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $join_char = $self->join_char;
    for my $match (grep ref, data_at($self->path, $data)) {
        set_data($match, $key,
            map { is_array_ref($_) ? join($join_char, @$_) : $_ }
                get_data($match, $key));
    }

    $data;
}

=head1 NAME

Catmandu::Fix::join_field - join the ARRAY values of a field into a string

=head1 SYNOPSIS

   # Join the array values of a field into a string. E.g. foo => [1,2,3]
   join_field('foo','/'); # foo => "1/2/3"

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
