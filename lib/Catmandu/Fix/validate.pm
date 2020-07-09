package Catmandu::Fix::validate;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util qw(require_package);
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

has path           => (fix_arg => 1);
has name           => (fix_arg => 1);
has error_field    => (fix_opt => 1, default => 'errors');
has validator_opts => (fix_opt => 'collect');
has validator      => (is      => 'lazy', init_arg => undef);

with 'Catmandu::Fix::Builder';

sub _build_validator {
    my ($self) = @_;
    require_package($self->name, 'Catmandu::Validator')
        ->new($self->validator_opts);
}

sub _build_fixer {
    my ($self) = @_;

    my $validator = $self->validator;
    my $get       = as_path($self->path)->getter;
    my $set_error = as_path($self->error_field)->creator;

    sub {
        my ($data) = @_;
        my $values = $get->($data);
        for my $val (@$values) {
            next if $validator->is_valid($val);
            $set_error->($data, $validator->last_errors);
        }
        $data;
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::validate - validate data and keep errors

=head1 SYNOPSIS

   # Check author field against a JSON Schema
   validate('author', JSONSchema, schema: 'my/schema.json')
   if exists(errors)
      ... # do something
   end

   # Check item against a custom validator, store in errors in 'warnings'
   validate('author', MyValidatorClass, error_field: warnings)

=head1 DESCRIPTION

This L<Catmandu::Fix> validates data with a L<Catmandu::Validator> and stores
errors in field C<errors> for further inspection.

=head1 CONFIGURATION

=over

=item error_field

Path where to store errors. Set to C<errors> by default.

=back

Additional options are passed to the validator.

=head1 SEE ALSO

L<Catmandu::Fix::Condition::valid>

=cut
