package Catmandu::Fix::append;

use Catmandu::Sane;

our $VERSION = '1.09';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path  => (fix_arg => 1);
has value => (fix_arg => 1);

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;
    my $val = $self->value;
    $self->_as_path($self->path)
        ->updater(if => [value => sub {join('', $_[0], $val)}],);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::append - add a suffix to the value of a field

=head1 SYNOPSIS

   # append to a value. e.g. {name => 'joe'}
   append(name, y) # {name => 'joey'}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
