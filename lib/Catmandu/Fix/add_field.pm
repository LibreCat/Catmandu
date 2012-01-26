package Catmandu::Fix::add_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is data_at);
use Moo;

has path  => (is => 'ro', required => 1);
has key   => (is => 'ro', required => 1);
has value => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $value) = @_;
    $path = [split /\./, $path];
    my $key = pop @$path;
    $orig->($class, path => $path, key => $key, value => $value);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $val = $self->value;
    my @matches = grep ref, data_at($self->path, $data, create => 1);
    for my $match (@matches) {
        if (is_array_ref($match)) {
            $match->[$key] = $val if is_integer($key);
        } else {
            $match->{$key} = $val;
        }
    }

    $data;
}

1;
