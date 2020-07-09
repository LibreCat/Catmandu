package Catmandu::Fix::format;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);
has spec => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    my $spec = $self->spec;
    as_path($self->path)->updater(
        if_string    => sub {sprintf($spec, $_[0])},
        if_array_ref => sub {sprintf($spec, @{$_[0]})},
        if_hash_ref  => sub {sprintf($spec, %{$_[0]})},
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::format - replace the value with a formatted (sprintf-like) version

=head1 SYNOPSIS

   # e.g. number: 41
   format(number,"%-10.10d") # number => "0000000041"

   # e.g. numbers: 
   #         - 41
   #         - 15
   format(number,"%-10.10d %-5.5d") # numbers => "0000000041 00015"

   # e.g. hash:
   #        name: Albert
   format(name,"%-10s: %s") # hash: "name      : Albert"

   # e.g. array:
   #         - 1
   format(array,"%d %d %d") # Fails! The array contains only one value, but you request 3 values 

   # Test first if the array contains 3 values
   if exists(array.2)
     format(array,"%d %d %d")
   end

=head1 DESCRIPTION

Create a string formatted by the usual printf conventions of the C library function sprintf. 
See L<http://perldoc.perl.org/functions/sprintf.html> for a complete description.

=head1 SEE ALSO

L<Catmandu::Fix> , L<sprintf>

=cut
