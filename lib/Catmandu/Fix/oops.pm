package Catmandu::Fix::oops;

use Catmandu::Sane;

our $VERSION = '1.08';

use Moo;
use Catmandu::Util qw(:is);
use Catmandu::Fix::Has;

has message     => (fix_arg => 1, required => 0);
has error_field => (fix_opt => 1, default => 'errors');

sub fix {
    my ($self, $data) = @_;

    my @messages = $self->{message};

    my $errors = $data->{$self->error_field // 'errors'};
    if ($errors) {
        if (is_array_ref($errors)) {
            push @messages, map { $self->_error_message($_) } @$errors;
        } else {
            push @messages, $self->_error_message($errors);
        }
    }

    my $msg = join "\n", grep { defined $_ } @messages;
	$msg = 'Oops!' if $msg eq '';

    # errors cannot be thrown in compiled fixes
    Catmandu::Error->throw($msg);
}

sub _error_message {
    my ($self, $error) = @_;

    if (is_hash_ref($error)) {
        $error = $error->{message}
    }

    return $error // 'Oops!';
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::oops - abort execution with error messages

=head1 SYNOPSIS

On the command line:

   catmandu convert JSON --fix 'oops("I'm sorry, Dave")'
   echo $?

To abort validation with error messages in a Fix script:

   validate('author', JSONSchema, schema: 'my/schema.json')
   if exists(errors)
      oops('validation failed:')
   end

=head1 DESCRIPTION

This Fix function throws an error to terminate execution of Catmandu with
nonzero exit code and print error message to STDERR. The error message can be
passed as string and/or it is read from field C<errors>. This error field can
be configured with option C<error_field> but path expressions are not
supported. Individual error messages can be plain strings or objects with field
C<message>.

=head1 SEE ALSO

L<Catmandu::Fix>

L<Catmandu::Fix::validate>

=cut
