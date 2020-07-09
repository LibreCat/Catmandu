package Catmandu::Validator::Mock;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use namespace::clean;

with 'Catmandu::Validator';

has message => (is => 'rw', default => sub {'item is invalid'});

has reject => (is => 'rw', default => sub {0});

sub validate_data {
    my ($self) = @_;

    if ($self->reject) {
        return [$self->message];
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Validator::Mock - Validate items based on a flag

=head1 SYNOPSIS

    use Catmandu::Validator::Mock;

    my $validator = Catmandu::Validator::Mock->new(
        message  => 'item is invalid',
        reject   => 1,
    );

=head1 DESCRIPTION

This L<Catmandu::Validator> can be used for testing as it does not actually
look at the data to validate. Instead it rejects items if C<reject> is set to a
true value.

=head1 CONFIGURATION

=over

=item message

Error message to return for rejected items.

=item reject

The validator marks all items as invalid as long as this flag is true. Default
is false.

=back

=head1 SEE ALSO

See L<Catmandu::Validator> for inherited methods, common configuration options,
and usage.

=cut
