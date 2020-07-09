package Catmandu::Fix::split_field;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

has path       => (fix_arg => 1);
has split_char => (fix_arg => 1, default => sub {qr'\s+'});

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;
    my $split_char = $self->split_char;
    as_path($self->path)
        ->updater(if_value => sub {[split $split_char, $_[0]]});
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::split_field - split a string value in a field into an ARRAY

=head1 SYNOPSIS

   # Split the 'foo' value into an array. E.g. foo => '1:2:3'
   split_field(foo, ':') # foo => [1,2,3]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
