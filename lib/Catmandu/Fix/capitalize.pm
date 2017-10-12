package Catmandu::Fix::capitalize;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo;
use Catmandu::Util qw(as_path as_utf8);
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1, coerce => \&as_path);
has updater => (is => 'lazy');

sub _build_updater {
    my ($self) = @_;
    $self->path->updater(if => [string => sub {ucfirst(lc(as_utf8($_[0])))}],
    );
}

sub fix {
    $_[0]->updater->($_[1]);
    $_[1];
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
