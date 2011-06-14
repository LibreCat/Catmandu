package Catmandu::Importer::CSV;
use Catmandu::Sane;
use Catmandu::Util qw(io);
use Text::CSV;
use Encode ();
use Catmandu::Object
    file => { default => sub { *STDIN } },
    quote_char => { default => sub { '"' } },
    split_char => { default => sub { ',' } };

sub each {
    my ($self, $sub) = @_;

    my $file = io $self->file, 'r';

    my $csv = Text::CSV->new({
        binary     => 1,
        quote_char => $self->quote_char,
        sep_char   => $self->split_char,
    });

    my $keys = $csv->getline($file);

    my $num_cols = @$keys;

    my $n = 0;

    my $row;
    my $obj;
    my $val;
    my $i;
    while ($row = $csv->getline($file)) {
        $obj = {};
        for ($i = 0; $i < $num_cols; $i++) {
            $val = $row->[$i] and $obj->{$keys->[$i]} = Encode::decode_utf8($val);
        }
        $sub->($obj);
        $n++;
    }

    $n;
}

1;
