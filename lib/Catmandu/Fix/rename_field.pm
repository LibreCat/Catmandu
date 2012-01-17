package Catmandu::Fix::rename_field;

use Catmandu::Sane;
use Catmandu::Util qw(:is data_at);
use Moo;

has path    => (is => 'ro', required => 1);
has old_key => (is => 'ro', required => 1);
has new_key => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $new_key) = @_;
    $path = [split /\./, $path];
    my $old_key = pop @$path;
    $orig->($class, path => $path, old_key => $old_key, new_key => $new_key);
};

sub fix {
    my ($self, $data) = @_;

    my $old_key = $self->old_key;
    my $new_key = $self->new_key;
    for my $match (data_at($self->path, $data)) {
        if (is_array_ref($match) && exists $match->{$old_key}) {
            $match->{$new_key} = delete $match->{$old_key};
        }
    }

    $data;
}

1;
