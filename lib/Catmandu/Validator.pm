package Catmandu::Validator;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo::Role;

requires 'validate_hash';

has 'last_errors' => (
      is     => 'rwp',
      clearer => '_clear_last_errors',
      init_arg => undef,
);

has 'after_callback' => (
    is => 'rw',
    clearer => 1,
);

has 'error_callback' => (
    is => 'rw',
    clearer => 1,
);


has 'error_field' => (
    is => 'rw',
    clearer => 1,
);

has ['count_valid', 'count_invalid'] => (
    is => 'rwp',
    init_arg => undef,
    default => sub {0},
);


sub is_valid {
    shift->validate(@_) ? 1 : 0;
}


sub validate {
    my ($self, $data, $options) = @_;
    
    if (! is_hash_ref($data) ) {
        Catmandu::BadArg->throw('Cannot validate data of this type');
    }
    
    $self->_clear_last_errors;
    $self->_set_count_valid(0);
    $self->_set_count_invalid(0);

    my $errors = $self->validate_hash($data, $options);

    if ($errors) {
        $self->_set_last_errors($errors);
        $self->_set_count_invalid(1);
        return;
    } else {
        $self->_set_count_valid(1);
    }

    $data; 
}


sub validate_many {
    my ($self, $data, $options) = @_;

    $self->_set_count_valid(0);
    $self->_set_count_invalid(0);

    # Update options if passed
    
    for ( qw(after_callback error_callback error_field) ) {
        $self->$_( $options->{$_} ) if exists $options->{$_}
    }

    # Handle a single record
    if ( is_hash_ref($data) ) {
        return $self->_process_record($data);
    }
    
    # Handle arrayref, returns a new arrayref
    if ( is_array_ref($data) ) {
        return [grep {defined} map {
             $self->_process_record($_)
        } @$data];
    }
   
    # Handle iterators, returns a new iterator
    if ( is_invocant($data) ) {
        return $data->select( sub { $self->_process_record($_[0]) } );
    }
    
    Catmandu::BadArg->throw('Cannot validate data of this type'); 
}

sub _process_record {
    my $self = shift;
    my ($data)  = @_;

    my $error_field = 
        ($self->error_field||0) eq '1'
        ? '_validation_errors'
        : $self->error_field;
 
    $self->_clear_last_errors;
    my $errors =  $self->validate_hash($data);
    $self->_set_last_errors($errors);
    
    if ($errors) {
        $self->_set_count_invalid(1+$self->count_invalid);
    } else {
        $self->_set_count_valid(1+$self->count_valid);
    }

    if ( $errors && $error_field ) {
        $data->{$error_field} = $errors;
    } else {
    }
    
    if ( $self->after_callback ) {
        return &{$self->after_callback}($data,$errors);
    }
    
    if ( $errors && $self->error_callback ) {
        &{$self->error_callback}($data,$errors);
        return;
    }
    
    return if $errors && !$error_field;
  
    $data;
} 



=head1 NAME

Catmandu::Validator - Namespace for packages that can validate records in Catmandu.

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
        reject_form($validator->last_errors);
    }
    
        
    my $new_options = {
        error_callback => sub {
            my ($data, $errors) = @_;
            print "Validation Errors for record $data->{_id}:\n";
            print "Error message: $_->{message}\n" for @{$errors};
        }
    };
    
    my $validated_arrayref = $validator->validate_many($arrayref, $new_options);

    #together with iterators:
    
    $validator->validate_many($iterator, {
        after_callback => sub {
            my ($record, $errors) = @_;
            if ($errors) {
                add_to_failure_report($rec, $errors);
                #omit the invalid record from the result
                return undef;
            }
            return $rec;
        }
    })->each( sub {
        my $record = shift;
        publish_record($record);
    });
  
 
=head1 DESCRIPTION

    A Catmandu::Validator is a base class for Perl packages that can validate data.

=head1 METHODS

=head2 new()

Create a new Catmandu::Validator.

=head2 new( after_callback => \&callback )

Used when validating multiple records the after_callback is called after each record has been validated.
The callback function should take $hashref to each data record, and $arrayref to list of validation errors
for the record as arguments.

=head2 new( error_field => $field_name )

If the error_field parameter is set, then during validation each record that
fails validation will get an extra field added containing an
arrayref to the validation errors. The name of the key will be the
value passed or '_validation_errors' if 1 is passed. By default it is not set.

=head2 validate( \%hash )

Validates a single record. Returns \%hash on success otherwise undef. Information about the validation errors
can be retrieved with the L</"last_errors()"> method. 

=head2 is_valid( \%hash )

Like L</"validate()"> but returns 1 success and 0 on failure.

=head2 validate_many( $iterator, \%options )

=head2 validate_many( \@array,   \%options )

Validates multiple records in an iterator or an array. Returns validated records in the same type of
container. The default behaviour is to return the records that passed validation unchanged and omit the invalid records.
This behaviour can be changed by setting the I<after_callback> or the I<error_field> in the options or in the constructor.

=head2 last_errors()

Returns arrayref of errors from the record that was last validated if that record failed validation
or undef if there were no errors.

=head2 count_valid()

Returns the number of valid_records from last validate_many or validate operation.

=head2 count_invalid()

Returns the number of invalid_records from last validate_many or validate operation.

=head1 SEE ALSO

L<Catmandu::Validator::Simple>, L<Catmandu::Iterable>

=cut

1;
