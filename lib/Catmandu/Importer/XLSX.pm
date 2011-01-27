package Catmandu::Importer::XLSX;
# ABSTRACT: An MS Excel 2007 importer
# VERSION
use Spreadsheet::XLSX;
use List::MoreUtils qw(zip);
use Moose;

with qw(Catmandu::Importer);

sub each {
    my ($self, $sub) = @_;

    if ($self->file->can('seek')) {
	$self->file->seek(0,0); #rewind
    }

    my $parser     = Spreadsheet::XLSX->new($self->file);
    my @worksheets = @{ $parser->{Worksheet} }; 
    my $sheet      = $worksheets[0];
    my $data       = &_load_data($sheet);

    my $n = 0;

    foreach my $obj (@$data) {
	$n++;
	$sub->($obj) if $sub;
    }

    $n;
}

sub _load_data {
    my $sheet = shift;
    $sheet->{MaxRow} ||= $sheet->{MinRow}; 

    my @out = ();

    foreach my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
	my @col = ();
	$sheet -> {MaxCol} ||= $sheet -> {MinCol};
	
	foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
	   my $cell = $sheet->{Cells}[$row][$col];
	   my $val  = $cell->{Val};

	   push(@col,$val);
	}

	push(@out, [ @col ]);
    }
  
    my @ret = ();

    my $header = shift @out;

    foreach my $row (@out) {
	my %hash = zip @$header , @$row;
	push @ret , \%hash;
    }

    \@ret;
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

=head1 SYNOPSIS

 use Catmandu::Importer::XLSX;

 my $importer = Catmandu::Importer::XLSX(file => 'test.xlsx');

 $importer->each(sub {
   my $object = shift;
 });

 or via the command line

 catmandu convert -I XLSX -o pretty=1 test.csv

 catmandu import -I XLSX -o path=data/test.db test.csv

=head1 METHODS

=head2 $c->new(file => $file)

Creates a new Catmandu::Importer::CSV instance to parse MS Excel 2007 data from $file into
Perl hashes.

=head2 $c->each($callback)

Execute $callback for every record imported. The callback functions get as 
first argument the parsed object (a ref hash of key => [ values ]). Returns
the number of objects in the stream.

=head1 SEE ALSO

L<Catmandu::Importer>
