package Catmandu::Importer::Spreadsheet;
use Catmandu::Sane;
use Spreadsheet::Read;
use Encode ();
use Catmandu::Object file => 'r';

sub each {
    my ($self, $sub) = @_;

    # TODO only handles a file, not a stream like the other importers
    my $ss = ReadData($self->file);

    my $n = $ss->[1]->{maxrow} - 1;

    my @rows = Spreadsheet::Read::rows($ss->[1]);
    my $keys = shift @rows;
    my $num_cols = @$keys;

    undef $ss;

    my $row;
    my $obj;
    my $val;
    my $i;
    for $row (@rows) {
        $obj = {};
        for ($i = 0; $i < $num_cols; $i++) {
            $val = $row->[$i] and $obj->{$keys->[$i]} = Encode::decode_utf8($val);
        }
        $sub->($obj);
    }

    $n;
}

=head1 NAME

Catmandu::Importer::Spreadsheet - Package that imports spreadsheets

=head1 SYNOPSIS

    use Catmandu::Importer::Spreadsheet;

    my $importer = Catmandu::Importer::Spreadsheet->new(file => "/foo/bar.xslx");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new([file => $filename])

Create a new Spreadsheet importer for $filename. Use STDIN when no filename is given.
This module supports Microsoft Excel and Open Office formats.

=head2 each(&callback)

The each method imports the data and executes the callback function for
each item imported. Returns the number of items imported or undef on 
failure.

=cut

1;
