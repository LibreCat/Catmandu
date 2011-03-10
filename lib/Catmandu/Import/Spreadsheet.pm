package Catmandu::Import::Spreadsheet;
use Spreadsheet::Read;
use Encode ();
use Catmandu::Util;
use Catmandu::Class qw(file);

sub build {
    my ($self, $args) = @_;
    $self->{file} = $args->{file} || confess("Attribute file is required");
}

sub default_attribute {
    'file';
}

sub each {
    my ($self, $sub) = @_;

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

no Spreadsheet::Read;
1;
