package Catmandu::Validator::Simple;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use namespace::clean;

with 'Catmandu::Validator';

has handler => (
    is       => 'rw',
    required => 1,
    isa      => sub {
        Catmandu::BadArg->throw("handler should be a CODE reference")
            unless ref $_[0] eq 'CODE';
    },
);

sub validate_data {
    my ($self, $data) = @_;

    my $error_messages = &{$self->handler}($data);
    $error_messages = [$error_messages]
        unless !$error_messages || ref $error_messages eq 'ARRAY';
    return $error_messages;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Validator::Simple - Simple Validator for Catmandu

=head1 SYNOPSIS

    use Catmandu::Validator::Simple;

    my $validator = Catmandu::Validator::Simple->new(
        handler => sub {
            $data = shift;
            return "error" unless $data->{title} =~ m/good title/;
            return;
        }
    );

    if ( $validator->is_valid($hashref) ) {
        save_record_in_database($hashref);
    } else {
        reject_form($validator->last_errors);
    }


=head1 DESCRIPTION

Catmandu::Validator::Simple can be used for doing simple data validation in
Catmandu.

=head1 METHODS

=head2 new(handler => \&callback, %options)

The I<callback> function should take $hashref to a data record as argument.
Should return undef if the record passes validation otherwise return an error
or an arrayref of errors.  Each error can be either a simple message string or
a hashref to a more detailed error information.

The constructor also accepts the common options for L<Catmandu::Validator>.

=head2 is_valid(...)

=head2 validate(...)

=head2 last_errors(...)

=head2 valid_count()

=head2 invalid_count()

These are methods are inherited from L<Catmandu::Validator>.

=head1 SEE ALSO

L<Catmandu::Validator>

=cut
