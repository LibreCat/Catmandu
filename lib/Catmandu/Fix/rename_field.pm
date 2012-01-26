package Catmandu::Fix::rename_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is data_at);
use Moo;

has path  => (is => 'ro', required => 1);
has path2 => (is => 'ro', required => 1);
has key   => (is => 'ro', required => 1);
has key2  => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $path2) = @_;
    $path = [split /\./, $path];
    my $key = pop @$path;
    $path2 = [split /\./, $path2];
    my $key2 = pop @$path2;
    $orig->($class, path => $path, key => $key, path2 => $path2, key2 => $key2);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $key2 = $self->key2;

    my @matches  = grep ref, data_at($self->path, $data, create => 1);
    my $match2   = [grep ref, data_at($self->path2, $data, create => 1)]->[0];

    for my $match (@matches) {
        if (is_array_ref($match2)) {
            $match2->[$key2] = is_array_ref($match) ? delete $match->[$key] : delete $match->{$key};
        }
        else {
	    $match2->{$key2} = is_array_ref($match) ? delete $match->[$key] : delete $match->{$key};
	}
    }

    $data;
}

1;
