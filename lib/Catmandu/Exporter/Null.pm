package Catmandu::Exporter::Null;

use namespace::clean;
use Catmandu::Sane;
use Moo;

with 'Catmandu::Exporter';

sub add {}

1;
__END__

=head1 NAME

Catmandu::Exporter::Null - a expoter that doesn't export anything

=head1 SYNOPSIS

  	# From the commandline
  	$ catmandu convert JSON --fix myfixes to Null < /tmp/data.json

=head1 DESCRIPTION

This exporter exports nothing and can be used as in situations where you e.g. export
data from a fix.

=head1 CONFIGURATION

=item file

=item fh

=item fix

=item encoding

Default options of L<Catmandu::Exporter>

=head1 SEE ALSO

L<Catmandu::Importer::Mock>

=cut
