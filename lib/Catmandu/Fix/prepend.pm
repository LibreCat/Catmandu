package Catmandu::Fix::prepend;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Moo;

has path  => (is => 'ro', required => 1);
has key   => (is => 'ro', required => 1);
has value => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $value) = @_;
    my ($p, $key) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, value => $value);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $value = $self->value;
    for my $match (grep ref, data_at($self->path, $data)) {
        set_data($match, $key,
            map { is_value($_) ? "$value$_" : $_ }
                get_data($match, $key));
    }

    $data;
}

sub emit {
    my ($self, $fixer) = @_;
    my $path_to_key = $self->path;
    my $key = $self->key;
    my $value = $fixer->emit_string($self->value);

    $fixer->emit_walk_path($fixer->var, $path_to_key, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "${var} = join('', $value, ${var}) if is_value(${var});";
        });
    });
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
