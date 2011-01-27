package Catmandu::Importer::CSV;
# ABSTRACT: Streaming CSV importer
# VERSION
use Text::CSV::Slurp;
use Moose;

with qw(Catmandu::Importer);

sub each {
    my ($self, $sub) = @_;

    if ($self->file->can('seek')) {
	$self->file->seek(0,0); #rewind
    }

    my $data = Text::CSV::Slurp->load(filehandle => $self->file);

    my $n = 0;

    foreach my $obj (@$data) {
	$n++;
	$sub->($obj) if $sub;
    }

    $n;
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

=head1 SYNOPSIS

 use Catmandu::Importer::CSV;

 my $importer = Catmandu::Importer::CSV(file => 'test.csv');

 $importer->each(sub {
   my $object = shift;
 });

 or via the command line

 catmandu convert -I CSV -o pretty=1 test.csv

 catmandu import -I CSV -o path=data/test.db test.csv

=head1 METHODS

=head2 $c->new(file => $file)

Creates a new Catmandu::Importer::CSV instance to parse CSV data from $file into
Perl hashes.

=head2 $c->each($callback)

Execute $callback for every record imported. The callback functions get as 
first argument the parsed object (a ref hash of key => [ values ]). Returns
the number of objects in the stream.

=head1 SEE ALSO

L<Catmandu::Importer>
