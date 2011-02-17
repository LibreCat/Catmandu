package Catmandu::Importer::CSV;
# ABSTRACT: Streaming CSV importer
# VERSION
use Moose;
use MooseX::Aliases;
use Text::CSV;
use Encode ();

with qw(
    Catmandu::FileReader
    Catmandu::Importer
);

has quote_char => (
    is => 'ro',
    isa => 'Str',
    alias => [qw(quote)],
    default => '"',
);

has sep_char => (
    is => 'ro',
    isa => 'Str',
    alias => [qw(sep)],
    default => ',',
);

sub default_attribute {
    'file';
}

sub each {
    my ($self, $sub) = @_;

    my $file = $self->file;
    my $csv  = Text::CSV->new({
        binary => 1,
        sep_char => $self->sep_char,
        quote_char => $self->quote_char,
    });
    my $keys = $csv->getline($file);
    my $cols = @$keys;

    my $n = 0;

    my $row;
    my $obj;
    my $val;
    my $i;
    while ($row = $csv->getline($file)) {
        $obj = {};
        for ($i = 0; $i < $cols; $i++) {
            $val = $row->[$i] and $obj->{$keys->[$i]} = Encode::decode_utf8($val);
        }
        $sub->($obj);
        $n++;
    }

    $n;
}

__PACKAGE__->meta->make_immutable;
no MooseX::Aliases;
no Moose;
1;

