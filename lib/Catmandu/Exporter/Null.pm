package Catmandu::Exporter::Null;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Moo;
use namespace::clean;

with 'Catmandu::Exporter';

sub add { }

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::Null - a expoter that doesn't export anything

=head1 SYNOPSIS

  	# From the commandline
  	$ catmandu convert JSON --fix myfixes to Null < /tmp/data.json

	$ catmandu convert JSON --fix 'add_to_exporter(.,JSON)' to Null < /tmp/data.json
	
=head1 DESCRIPTION

This exporter exports nothing and can be used as in situations where you export
data in the Fix script itself.

=head1 SEE ALSO

L<Catmandu::Importer::Mock>

=cut
