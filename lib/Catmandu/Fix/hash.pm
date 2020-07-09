package Catmandu::Fix::hash;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)->updater(if_array_ref => sub {+{@{$_[0]}}});
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::hash - creates a hash out of an array

=head1 SYNOPSIS

   # tags => ['name', 'Peter', 'age', 12]
   hash(tags)
   # tags => {name => 'Peter', age => 12}

=head1 DESCRIPTION

This fix functions transforms array fields to hashes. The number of array
elements must be even and fields to be used as field values must be simple
strings. String fields and hash fields are left unchanged.

=head1 SEE ALSO

L<Catmandu::Fix::array>, L<Catmandu::Fix>

=cut
