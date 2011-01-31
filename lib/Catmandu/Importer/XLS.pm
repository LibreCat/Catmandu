package Catmandu::Importer::XLS;
# ABSTRACT: An MS Excel importer
# VERSION
use Spreadsheet::ParseExcel;
use List::MoreUtils qw(zip);
use Moose;

with qw(Catmandu::Importer);

sub each {
    my ($self, $sub) = @_;

    if ($self->file->can('seek')) {
	$self->file->seek(0,0); #rewind
    }

    my $parser     = Spreadsheet::ParseExcel->new();
    my $workbook   = $parser->parse($self->file);
    my @worksheets = $workbook->worksheets();
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
    my ( $row_min, $row_max ) = $sheet->row_range();
    my ( $col_min, $col_max ) = $sheet->col_range();

    my @out = ();

    foreach my $row ($row_min .. $row_max) {
	my @col = ();
	
	foreach my $col ($col_min .. $col_max) {
	   my $cell = $sheet->get_cell($row,$col);
           my $val  = undef;
	   
	   $val  = $cell->value() if $cell;

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

 use Catmandu::Importer::XLS;

 my $importer = Catmandu::Importer::XLS(file => 'test.xls');

 $importer->each(sub {
   my $object = shift;
 });

 or via the command line

 catmandu convert -I XLS -o pretty=1 test.csv

 catmandu import -I XLS -o path=data/test.db test.csv

=head1 METHODS

=head2 $c->new(file => $file)

Creates a new Catmandu::Importer::CSV instance to parse MS Excel data from $file into
Perl hashes.

=head2 $c->each($callback)

Execute $callback for every record imported. The callback functions get as 
first argument the parsed object (a ref hash of key => [ values ]). Returns
the number of objects in the stream.

=head1 SEE ALSO

L<Catmandu::Importer>
