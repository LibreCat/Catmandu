package Catmandu::Validator::Simple;

use Catmandu::Sane;

our $VERSION = '1.2013';

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

=head1 CONFIGURATION

=over

=item handler

A function that takes a hash reference item as argument. Should return undef if
the record passes validation otherwise return an error or an arrayref of
errors.  Each error can be either a simple message string or a hashref to a
more detailed error information.

=back

=head1 SEE ALSO

See L<Catmandu::Validator> for inherited methods, common configuration options,
and usage.

=cut
