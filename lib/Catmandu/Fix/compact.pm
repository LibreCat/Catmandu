package Catmandu::Fix::compact;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)
        ->updater(if_array_ref => sub {[grep defined, @{$_[0]}]});
}

=head1 NAME

Catmandu::Fix::compact - remove undefined values from an array

=head1 SYNOPSIS

   # list => [undef,"hello",undef,"world"]
   compact(list)
   # list => ["Hello","world"]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
