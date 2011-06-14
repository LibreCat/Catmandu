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

1;
