package Catmandu::Validator::Blind;

use Catmandu::Sane;

our $VERSION = '1.08';

use Moo;
use namespace::clean;

with 'Catmandu::Validator';

has message => (
    is      => 'rw',
    default => sub {'item randomly marked as invalid'}
);

has rate => (
    is      => 'rw',
    default => sub {0}
);

sub validate_data {
    my ($self, $data) = @_;

    if ($self->rate && rand() < $self->rate) {
        return [ $self->message ];
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Validator::Blind - Validator that randomly rejects items

=head1 SYNOPSIS

    use Catmandu::Validator::Blind;

    my $validator = Catmandu::Validator::Blind->new(
        message => 'on average every 10th item is rejected',
        rate    => 0.1,
    );

=head1 DESCRIPTION

This L<Catmandu::Validator> can be used for testing as it does not actually
look at the data to validate. Instead it randomly rejects items with a given
rate. By default no items are rejected.

=head1 CONFIGURATION

=over

=item message

Error message to return for rejected items.

=item rate

Percentage of items to reject given as number between zero (all items are
valid) and one (all items are invalid).

=back

=head1 SEE ALSO

See L<Catmandu::Validator> for inherited methods, common configuration options,
and usage.

=cut
