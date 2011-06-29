package Catmandu::Importer::CSV;
use Catmandu::Sane;
use Catmandu::Util qw(io);
use Text::CSV;
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

    my $fields = $csv->getline($file);

    $csv->column_names($fields);

    my $n = 0;

    while (my $obj = $csv->getline_hr($file)) {
        $sub->($obj);
        $n++;
    }

    $n;
}

1;
