package Catmandu::Validator::Env;

use Catmandu::Sane;

our $VERSION = '1.08';

use Moo;
use namespace::clean;

with 'Catmandu::Validator';

has message => (
    is      => 'rw',
    default => sub {'item marked as invalid'}
);

has variable => (
    is      => 'rw',
    default => sub {'CATMANDU_VALIDATOR_ENV'}
);

sub validate_data {
    my ($self, $data) = @_;

    if ($ENV{$self->variable}) {
        return [ $self->message ];
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Validator::Env - Validate items based on environment variable

=head1 SYNOPSIS

    use Catmandu::Validator::Env;

    my $validator = Catmandu::Validator::Env->new(
        message  => 'item is invalid',
        variable => 'REJECT_ALL',
    );

=head1 DESCRIPTION

This L<Catmandu::Validator> can be used for testing as it does not actually
look at the data to validate. Instead it rejects items if an environment
variable is set to a true value.

=head1 CONFIGURATION

=over

=item message

Error message to return for rejected items.

=item variable

Name of the environment variable to check. Set to C<CATMANDU_VALIDATOR_ENV> by
default.  The validator marks all items as invalid as long as this variable is
no set or false (empty string or C<0>).

=back

=head1 SEE ALSO

See L<Catmandu::Validator> for inherited methods, common configuration options,
and usage.

=cut
