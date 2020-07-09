package Catmandu::Fix::prepend;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

has path  => (fix_arg => 1);
has value => (fix_arg => 1);

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;
    my $val = $self->value;
    as_path($self->path)->updater(if_value => sub {join('', $val, $_[0])});
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::prepend - add a prefix to the value of a field

=head1 SYNOPSIS

   # prepend to a value. e.g. {name => 'smith'}
   prepend(name, 'mr. ') # {name => 'mr. smith'}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
