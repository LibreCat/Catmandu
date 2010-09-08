package Catmandu::Importer::JSON;

use strict;
use warnings;
use File::Slurp qw(slurp);
use JSON;
use Carp;

sub open {
  my ($pkg,$file,%args) = @_;
  my $json_text = slurp($file);
  my $perl_scalar = from_json($json_text);

  if (ref $perl_scalar ne 'ARRAY') {
    Carp::croak("Format error - $file doesn't return an ARRAY");
  }

  bless {
    data => $perl_scalar ,
  } , $pkg;
}

sub each {
  my $self = shift;
  my $callback = shift;

  my $count = 0;
  foreach my $obj (@{$self->{data}}) {
    &$callback($obj) if defined $callback;
    $count++;
  }

  $count;
} 

sub close {
  1;
}

1;

__END__

=head1 NAME

 Catmandu::Importer::JSON - An import interface for Bibliographic data structures

=head1 SYNOPSIS

 use Catmandu::Importer::JSON;

 my $importer = Catmandu::Importer::JSON->open($stream);

 while (my $obj = $importer->next()) {
  # process $obj ...
 }

 $importer->close();

=head1 METHODS

=over 4

=item open($stream) 

Opens an import file (URL? stream?) for record parsing. Returns a Catmandu::Importer or undef on failure.

=item next()

Returns the next Catmandu record or undef at the end of the stream.

=item close()

Closes the import file (URL? stream?).

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
