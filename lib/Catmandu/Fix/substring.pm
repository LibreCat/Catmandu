package Catmandu::Fix::substring;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Moo;

has path  => (is => 'ro', required => 1);
has key   => (is => 'ro', required => 1);
has args  => (is => 'ro', required => 1);
has guard => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $path, @args) = @_;
    my ($p, $key, $guard) = parse_data_path($path);
    $orig->($class, path => $p, key => $key, args => [@args], guard => $guard);
};

sub fix {
    my ($self, $data) = @_;

    my $key = $self->key;
    my $guard = $self->guard;
    my $args = $self->args;
    for my $match (grep ref, data_at($self->path, $data)) {
        set_data($match, $key,
            map { $guard->($_) && is_string($_) ? mysubstr($_, @$args) : $_ }
                get_data($match, $key));
    }

    $data;
}

sub mysubstr {
    if    (@_ == 2) { substr($_[0], $_[1]) }
    elsif (@_ == 3) { substr($_[0], $_[1], $_[2]) }
    elsif (@_ == 4) { substr($_[0], $_[1], $_[2], $_[3]) }
    else { confess "wrong number of arguments" }
}

=head1 NAME

Catmandu::Fix::substring - extract a substring out of the value of a field

=head1 SYNOPSIS

   # Extract a substring out of the value of a field
   substring('initials',0,1);

=head1 SEE ALSO

L<Catmandu::Fix>, substr

=cut

1;
