package Catmandu::Fix::error;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

has message => (fix_arg => 1);

sub fix {
    my ($self) = @_;
    die $self->message;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::error - die with an error message

=head1 SYNOPSIS

  unless exists(id)
    error('id missing!')
  end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

