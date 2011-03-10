package Catmandu::Import::CSV;
use Text::CSV;
use Encode ();
use Catmandu::Util;
use Catmandu::Class qw(file quote_char split_char);

sub build {
    my ($self, $args) = @_;
    $self->{file} = $args->{file} || *STDIN;
    $self->{quote_char} = $args->{quote_char} || $args->{quote} || '"';
    $self->{split_char} = $args->{split_char} || $args->{split} || ',';
}

sub default_attribute {
    'file';
}

sub each {
    my ($self, $sub) = @_;

    my $file = Catmandu::Util::io($self->file, 'r');

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
