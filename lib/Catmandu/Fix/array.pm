package Catmandu::Fix::array;

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
    as_path($self->path)->updater(if_hash_ref => sub {[%{$_[0]}]});
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::array - creates an array out of a hash

=head1 SYNOPSIS

   # tags => {name => 'Peter', age => 12}
   array(tags)
   # tags => ['name', 'Peter', 'age', 12]

=head1 DESCRIPTION

This fix functions transforms hash fields to array. String fields and array
fields are left unchanged.

=head1 SEE ALSO

L<Catmandu::Fix::hash>, L<Catmandu::Fix>

=cut
