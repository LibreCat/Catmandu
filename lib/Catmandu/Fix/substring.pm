package Catmandu::Fix::substring;

use Catmandu::Sane;
use Catmandu::Util qw(:is data_at);
use Moo;

has path => (is => 'ro', required => 1);
has key  => (is => 'ro', required => 1);
has args => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, @args) = @_;
    $path = [split /\./, $path];
    my $key = pop @$path;
    $orig->($class, path => $path, key => $key, args => [@args]);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $args = $self->args;
    
    my @matches = grep ref, data_at($self->path, $data);
    for my $match (@matches) {
        if (is_array_ref($match)) {
            is_integer($key) || next;
            my $val = $match->{$key};
            $match->[$key] = &mysubstr($val, @$args) if is_string($val);
        } else {
            my $val = $match->{$key};
            $match->{$key} = &mysubstr($val, @$args) if is_string($val);
        }
    }

    $data;
}

sub mysubstr {
    if    (@_ == 2) { substr($_[0], $_[1]) }
    elsif (@_ == 3) { substr($_[0], $_[1], $_[2]) }
    elsif (@_ == 4) { substr($_[0], $_[1], $_[2], $_[3]) }
    else { die }
}

1;
