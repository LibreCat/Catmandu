package Catmandu::Validator;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo::Role;

requires 'validate_hash';

has 'errors' => (
      is     => 'rwp',
      clearer => '_clear_errors',
      init_arg => undef,
);

has 'after_handler' => (
    is => 'rw',
    clearer => 1,
);

has 'error_info_field' => (
    is => 'rw',
    clearer => 1,
);

has ['count_valid', 'count_invalid'] => (
    is => 'rwp',
    init_arg => undef,
    default => sub {0},
);

sub validate {
    my ($self, $data, $options) = @_;
    
    $self->_clear_errors;
    $self->_set_count_valid(0);
    $self->_set_count_invalid(0);

    my $errors = $self->validate_hash($data, $options);
    if ($errors) {
        $self->_set_errors($errors);
        $self->_set_count_invalid(1);
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
    
    for ( qw(after_handler error_info_field) ) {
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

    my $error_info_field = 
        ($self->error_info_field||0) eq '1'
        ? '_validation_errors'
        : $self->error_info_field;
 
    $self->_clear_errors;
    my $errors =  $self->validate_hash($data);
    $self->_set_errors($errors);
    
    if ($errors) {
        $self->_set_count_invalid(1+$self->count_invalid);
    } else {
        $self->_set_count_valid(1+$self->count_valid);
    }
                
    if ( $errors && $error_info_field ) {
        $data->{$error_info_field} = $errors;
    }
    
    if ( $self->after_handler ) {
        return &{$self->after_handler}($data,$errors);
    }

    return if $errors;
  
    $data;
} 



=head1 NAME

Catmandu::Validator - Namespace for packages that can validate records in Catmandu

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

    #together with iterators:
    
    $validator->validate_many($iterator, {
        after_handler => sub {
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

    A Catmandu::Validator is a stub for validating data.....


=head1 METHODS

new()

Create a new Catmandu::Validator.

new(after_handler => \&callback)

Used when validating multiple records after_handler validating each record.
Reference to callback function that will takes $hashref to each data record, and  $arrayref to list of validation errors
for the record as arguments.


new(error_info_field => $field_name)

If this parameter is set, then during validaiton each record that
fails validation will get an extra field added containing an
arrayref to the validation errors. The name of the key will be the
value passed or '_validation_errors' if 1 is passed. By default it is not set.



-------------------------------

validate( \%hash )

validates a single record. Returns \%hash on success otherwise undef. Information about the validation erors
can be retrieved with the errors() method. 

validate_many( $iterator, \%options )
validate_many( \@array,   \%options )

Validates multiple records in an iterator or an array. Returns validated records in the same type of
container. The default behaviour is to return the records that passed validation unchanged and omit the invalid records.
This behaviour can be changed by setting the after_handler callback or the error_info field in the options or in the constructor.

errors()

Returns arrayref of errors from the record that was last validated if that record failed validation
or undef if there were no errors.

count_valid()

Returns the number of valid_records from last validate_many or validate operation

cound_invalid()

Returns the number of invalid_records from last validate_many or validate operation

=cut

1;
