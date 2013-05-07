package Catmandu::ArrayIterator;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(check_array_ref);
use Role::Tiny::With;

with 'Catmandu::Iterable';

sub new {
    bless check_array_ref($_[1]), $_[0];
}

sub generator {
    my ($self) = @_;
    my $i = 0;
    sub {
        $self->[$i++];
    };
}

sub to_array {
    [@{$_[0]}];
}

sub count {
    scalar @{$_[0]};
}

sub each {
    my ($self, $cb) = @_;
    $cb->($_) for @$self;
    $self->count;
}

sub first {
    $_[0]->[0];
}

1;

=head1 NAME

Catmandu::ArrayIterator - Convert an arrayref to an Iterable object

=head1 SYNOPSIS

    my $it = Catmandu::ArrayIterator->new([{n => 1}, {n => 2}, {n => 3}]);

    $it->[0];
    # => {n => 1}
    $it->first;
    # => {n => 1}
    $it->map(sub { $_[0]->{n} + 1 })->to_array;
    # => [2, 3, 4]

=head1 SEE ALSO

L<Catmandu::Iterable>, L<Catmandu::Iterator>

=cut
