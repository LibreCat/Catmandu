package Catmandu::Importer::Spreadsheet;
# ABSTRACT: Importer for csv, xls, xlsx, sxc, ods
# VERSION
use Moose;
use MooseX::Aliases;
use Spreadsheet::Read;

with qw(
    Catmandu::Importer
);

has path => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has format => (
    is => 'ro',
    isa => 'Str',
    alias => [qw(fmt)],
    builder => '_build_format',
);

has quote => (
    is => 'ro',
    isa => 'Str',
    default => '"',
);

has separator => (
    is => 'ro',
    isa => 'Str',
    alias => [qw(sep)],
    default => ',',
);

sub _build_format {
    my $self = $_[0];

    if (my ($format) = $self->path =~ /\.(csv|xls|xlsx|sxc|ods)$/) {
        $format;
    } else {
        'csv';
    }
}

sub default_attribute {
    'path';
}

sub each {
    my ($self, $sub) = @_;

    my $ss = ReadData($self->path,
        parser => $self->format,
        sep    => $self->separator,
        quote  => $self->quote,
    );

    my $n = $ss->[1]->{maxrow} - 1;

    my @rows = Spreadsheet::Read::rows($ss->[1]);
    my $keys = shift @rows;

    undef $ss;

    my $row;
    my $obj;
    my $val;
    my $i;
    for $row (@rows) {
        $obj = {};
        for ($i = 0; $i < @$keys; $i++) {
            $val = $row->[$i] and $obj->{$keys->[$i]} = $val;
        }
        $sub->($obj);
    }

    $n;
}

__PACKAGE__->meta->make_immutable;
no Spreadsheet::Read;
no Moose;
1;

