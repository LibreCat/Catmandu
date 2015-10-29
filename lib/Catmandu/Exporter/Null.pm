package Catmandu::Exporter::Null;

use Catmandu::Sane;

our $VERSION = '0.9502';

use Moo;
use namespace::clean;

with 'Catmandu::Exporter';

has exporters => (is => 'ro', default => sub { [] });

sub add {}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::Null - a expoter that doesn't export anything

=head1 SYNOPSIS

  	# From the commandline
  	$ catmandu convert JSON --fix myfixes to Null < /tmp/data.json

=head1 DESCRIPTION

This exporter exports nothing and can be used as in situations where you e.g. export
data from a fix.

=head1 SEE ALSO

L<Catmandu::Importer::Mock>

=cut
