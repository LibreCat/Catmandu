package Catmandu::Validator::Simple;

use Catmandu::Sane;
use Moo;

with  'Catmandu::Validator';

has validation_handler => (
    is  => 'rw',
    required => 1,
    isa => sub {
        Catmandu::BadArg->throw( "Validation_handler should be a CODE reference") unless ref $_[0] eq 'CODE',
    },
);


sub validate_hash  {
    my ($self, $data) = @_;

    my $error_messages = &{$self->validation_handler}($data);
    $error_messages = [$error_messages] unless !$error_messages || ref $error_messages eq 'ARRAY'; 
    return $error_messages;
}


=head1 NAME

Catmandu::Validator::Simple - Simple Validator for Catmandu

=head1 SYNOPSIS

    use Catmandu::Validator::Simple;

    my $validator = Catmandu::Validator::Simple->new(
        validation_handler => sub {
            $data = shift;
            return "error" unless $data =~ m/good data/;
            return;
        }
    );

    if ( $validator->validate($hashref) ) {
        save_record_in_database($hashref);
    } else {
        reject_form($validator->error_messages);
    }

    my $new_options = {
        error_handler => sub {            
            sub { Catmandu->log() }
            
            my ($data, $errors) = @_;
            if ($errors) {
                print "Validation Errors for record $data->{_id}:\n";
                print "Error message: $_\n" for @{$errors};
            }
        }
    };
    
    my $validated_arrayref = $validator->validate_many($arrayref, $new_options);


=head1 DESCRIPTION

Catmandu::Validator::Simple can be used for doing simple data validation in Catmandu.

=head1 METHODS

=head2 new(validation_handler => \&callback)

=head2 new(validation_handler => \&callback, %options)

The I<callback> function should take $hashref to a data record as argument.
Should return undef if the record passes validation otherwise return an error or an arrayref of errors.
Each error can be either a simple message string or a hashref to a more detailed error information. If a
hashref is used then it should include the error messages field as 'message'. Any other information is
optional.

The constructor also accepts the common options for L<Catmandu::Validator>.

=head2 validate(...)

=head2 is_valid(...)

=head2 validate_many(...)

=head2 last_errors(...)

=head2 count_valid()

=head2 count_invalid()

These are methods are inherited from L<Catmandu::Validator>.

=head1 SEE ALSO

L<Catmandu::Validator>

=cut

1;
