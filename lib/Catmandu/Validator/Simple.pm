package Catmandu::Validator::Simple;

use Catmandu::Sane;
use Moo;

with  'Catmandu::Validator';

has validation_handler => (
    is  => 'rw',
    required => 1,
    isa => sub {
        die "validation_hanlder should be a CODE reference" unless ref $_[0] eq 'CODE',
    },
);


sub validate_hash  {
    my ($self, $data) = @_;

    my $error_messages = &{$self->validation_handler}($data);
    $error_messages = [$error_messages]
        if $error_messages && ref $error_messages ne 'ARRAY';
    return (
        $error_messages
                     ?  [map {
                            ref $_ ? $_ : { message => $_}}
                            @$error_messages
                        ]
                     :  undef
    );
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
            my ($data, $errors) = @_;
            if ($errors) {
                print "Validation Errors for record $data->{_id}:\n";
                print "Error message: $_->{message}\n" for @{$errors};
            }
        }
    };
    
    my $validated_arrayref = $validator->validate_many($arrayref, $new_options);


=head1 DESCRIPTION

Catmandu::Validator::Simple is ....

=head1 METHODS

new(validation_handler => \&callback)
new(validation_handler => \&callback, %options)

validation_handler should be a callback function that will take $hashref to a data record as argument.
Should return undef if the record passes validation otherwise return an error or an arrayref of errors.
error can either be simple error message string or a hashref to a more detailed error information. If a
hashref is used then it should include the error messages field as 'message'. Any other information is
optional.

The constructor also optionally takes the common options for Catmandu::Validator.


validate(...)

validate_many(...)

errors(...)

error_messages(...)


These are methods inherited from Catmandu::Validator.

=head1 SEE ALSO

L<Catmandu::Validator>

=cut

1;
