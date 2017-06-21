package Catmandu::ArrayIterator;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Catmandu::Util qw(check_array_ref);
use Role::Tiny::With;
use namespace::clean;

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

__END__

=pod

=head1 NAME

Catmandu::ArrayIterator - Convert an arrayref to an Iterable object

=head1 SYNOPSIS

    use Catmandu::ArrayIterator;

    my $it = Catmandu::ArrayIterator->new([{n => 1}, {n => 2}, {n => 3}]);

    $it->each( sub {
        my $item = $_[0];
        # Very complicated routine
      ...
    });

    $it->[0];
    # => {n => 1}
    $it->first;
    # => {n => 1}
    $it->map(sub { $_[0]->{n} + 1 })->to_array;
    # => [2, 3, 4]
    $it->count
    # => 3

=head1 METHODS

=head2 new($arrayRef)

Create a new iterator object from $arrayRef.

=head2 to_array

Return all the items in the Iterator as an ARRAY ref.

=head2 each(\&callback)

For each item in the Iterator execute the callback function with the item as first argument. Returns
the number of items in the Iterator.

=head2 count

Return the count of all the items in the Iterator.

=head2 first

Return the first item from the Iterator.

=head1 SEE ALSO

L<Catmandu::Iterable>, L<Catmandu::Iterator>

=cut
