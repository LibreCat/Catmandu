package Catmandu::Fix::capitalize;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo;
use Catmandu::Util qw(as_path as_utf8);
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)
        ->updater(if => [string => sub {ucfirst(lc(as_utf8($_[0])))}],);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::capitalize - capitalize the value of a key

=head1 SYNOPSIS

   # Capitalize the value of foo. E.g. foo => 'bar'
   capitalize(foo)  # foo => 'Bar'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
