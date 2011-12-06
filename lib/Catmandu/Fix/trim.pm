package Catmandu::Fix::trim;

use Catmandu::Sane;
use Catmandu::Util qw(:is get_data_at trim);
use Moo;

has path => (is => 'ro', required => 1);
has key  => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    $path = [split /\./, $path];
    my $key = pop @$path;
    $orig->($class, path => $path, key => $key);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my @matches = grep ref, get_data_at($self->path, $data);
    for my $match (@matches) {
        if (is_array_ref($match)) {
            is_integer($key) || next;
            my $val = $match->{$key};
            $match->[$key] = trim($val) if is_string($val);
        } else {
            my $val = $match->{$key};
            $match->{$key} = trim($val) if is_string($val);
        }
    }

    $data;
}

1;
