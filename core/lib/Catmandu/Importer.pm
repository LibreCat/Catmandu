package Catmandu::Importer;

sub open {
  bless {}, shift;
}

sub next {
  {};
}

sub close {
   1;
} 

1;

__END__

=head1 NAME

 Catmandu::Importer - An import interface for Bibliographic data structures

=head1 SYNOPSIS

 use Catmandu::Importer;

 my $importer = Catmandu::Importer->open($stream);

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
