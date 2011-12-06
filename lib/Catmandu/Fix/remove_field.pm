package Catmandu::Fix::remove_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is get_data_at);
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
            splice @$match, $key, 1 if is_integer($key) && $key < @$match;
        } else {
            delete $match->{$key};
        }
    }

    $data;
}

1;
