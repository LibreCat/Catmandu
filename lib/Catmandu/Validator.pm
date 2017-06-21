package Catmandu::Validator;

use Catmandu::Sane;

our $VERSION = '1.06';

use Catmandu::Util qw(:is);
use Moo::Role;
use namespace::clean;

requires 'validate_data';

has 'last_errors' =>
    (is => 'rwp', clearer => '_clear_last_errors', init_arg => undef,);

has 'after_callback' => (is => 'ro', clearer => 1,);

has 'error_callback' => (is => 'ro', clearer => 1,);

has 'error_field' => (is => 'ro', clearer => 1,);

has ['valid_count', 'invalid_count'] =>
    (is => 'rwp', init_arg => undef, default => sub {0},);

sub is_valid {
    my ($self, $data) = @_;

    if (!is_hash_ref($data)) {
        Catmandu::BadArg->throw('Cannot validate data of this type');
    }

    $self->_clear_last_errors;
    $self->_set_valid_count(0);
    $self->_set_invalid_count(0);

    my $errors = $self->validate_data($data);

    if ($errors) {
        $self->_set_last_errors($errors);
        $self->_set_invalid_count(1);
        return 0;
    }
    else {
        $self->_set_valid_count(1);
    }

    1;
}

sub validate {
    my ($self, $data) = @_;

    $self->_set_valid_count(0);
    $self->_set_invalid_count(0);

    # handle a single record
    if (is_hash_ref($data)) {
        return $self->_process_record($data);
    }

    # handle arrayref, returns a new arrayref
    if (is_array_ref($data)) {
        return [grep {defined} map {$self->_process_record($_)} @$data];
    }

    # handle iterators, returns a new iterator
    if (is_invocant($data)) {
        return $data->select(sub {$self->_process_record($_[0])});
    }

    Catmandu::BadArg->throw('Cannot validate data of this type');
}

sub _process_record {
    my ($self, $data) = @_;

    my $error_field
        = ($self->error_field || 0) eq '1'
        ? '_validation_errors'
        : $self->error_field;

    $self->_clear_last_errors;
    my $errors = $self->validate_data($data);
    $self->_set_last_errors($errors);

    if ($errors) {
        $self->_set_invalid_count(1 + $self->invalid_count);
    }
    else {
        $self->_set_valid_count(1 + $self->valid_count);
    }

    if ($errors && $error_field) {
        $data->{$error_field} = $errors;
    }

    if ($self->after_callback) {
        return $self->after_callback->($data, $errors);
    }

    if ($errors && $self->error_callback) {
        $self->error_callback->($data, $errors);
        return;
    }

    return if $errors && !$error_field;

    $data;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Validator - Namespace for packages that can validate records in Catmandu.

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

    my $validator = Catmandu::Validator::Simple->new(
        handler => sub { ...},
        error_callback => sub {
            my ($data, $errors) = @_;
            print "Validation errors for record $data->{_id}:\n";
            print "$_\n" for @{$errors};
        }
    };

    my $validated_arrayref = $validator->validate($arrayref);

    $validator->validate($iterator, {
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

The after_callback is called after each record has been validated.
The callback function should take $hashref to each data record, and $arrayref to list of validation errors
for the record as arguments.

=head2 new( error_field => $field_name )

If the error_field parameter is set, then during validation each record that
fails validation will get an extra field added containing an
arrayref to the validation errors. The name of the key will be the
value passed or '_validation_errors' if 1 is passed. By default it is not set.

=head2 is_valid( \%hash )

Validates a single record. Returns 1 success and 0 on failure. Information about the validation errors
can be retrieved with the L</"last_errors()"> method.

=head2 validate( \%hash )

=head2 validate( $iterator )

=head2 validate( \@array )

Validates a single record or multiple records in an iterator or an array. Returns validated records in the same type of
container for multiple records or the record itself for a single record. The default behaviour is to return the records that passed validation unchanged and omit the invalid records.
This behaviour can be changed by setting the I<after_callback> or the I<error_field> in the constructor. Returns undef on validation failure for single records.

=head2 last_errors()

Returns arrayref of errors from the record that was last validated if that record failed validation
or undef if there were no errors.

=head2 valid_count()

Returns the number of valid records from last validate operation.

=head2 invalid_count()

Returns the number of invalid records from the last validate operation.

=head1 SEE ALSO

L<Catmandu::Validator::Simple>, L<Catmandu::Iterable>

=cut
