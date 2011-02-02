package Catmandu::Importer::Spreadsheet;
# ABSTRACT: Importer for csv, xls, xlsx, sxc, ods
# VERSION
use Moose;
use Moose::Util::TypeConstraints;
use Spreadsheet::Read;
use Encode ();

with qw(
    Catmandu::Importer
);

subtype 'Catmandu::Importer::Spreadsheet::Path'
    => as 'Str'
    => where { $_ =~ /\.(xls|xlsx|sxc|ods)$/ }
    => message { "The spreadsheet must be a .xls, .xlsx, .sxc or .ods file" };

has path => (
    is => 'ro',
    isa => 'Catmandu::Importer::Spreadsheet::Path',
    required => 1,
);

sub default_attribute {
    'path';
}

sub each {
    my ($self, $sub) = @_;

    my $ss = ReadData($self->path);

    my $n = $ss->[1]->{maxrow} - 1;

    my @rows = Spreadsheet::Read::rows($ss->[1]);
    my $keys = shift @rows;
    my $cols = @$keys;

    undef $ss;

    my $row;
    my $obj;
    my $val;
    my $i;
    for $row (@rows) {
        $obj = {};
        for ($i = 0; $i < $cols; $i++) {
            $val = $row->[$i] and $obj->{$keys->[$i]} = Encode::decode_utf8($val);
        }
        $sub->($obj);
    }

    $n;
}

__PACKAGE__->meta->make_immutable;
no Spreadsheet::Read;
no Moose::Util::TypeConstraints;
no Moose;
1;

