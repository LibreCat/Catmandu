package Catmandu::Fix::replace_all;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Data::Dumper;
use Moo;

has path    => (is => 'ro', required => 1);
has key     => (is => 'ro', required => 1);
has search  => (is => 'ro', required => 1);
has replace => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $search, $replace) = @_;
    my ($p, $key) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, search => $search, replace => $replace);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $search  = $self->search;
    my $replace = $self->replace; 

    my @matches = grep ref, data_at($self->path, $data, key => $key);

    for my $match (@matches) {
        if (is_array_ref($match)) {
            is_integer($key) || next;
            my $val = $match->[$key];
            $match->[$key] =~ s{$search}{$replace}g if is_string($val);
        } else {
            my $val = $match->{$key};
            $match->{$key} =~ s{$search}{$replace}g if is_string($val);
        }
    }

    $data;
}

=head1 NAME

Catmandu::Fix::replace_all - search and replace using regex expressions

=head1 SYNOPSIS

   # Extract a substring out of the value of a field
   replace_all('year','\^','0');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
