package Catmandu::Importer::CSV;

use Catmandu::Sane;
use Moo;
use Text::CSV;

with 'Catmandu::Importer';

has csv        => (is => 'ro', lazy => 1, builder => '_build_csv');
has quote_char => (is => 'ro', default => sub { '"' });
has split_char => (is => 'ro', default => sub { ',' });
has header     => (is => 'ro', default => sub { 1 });
has fields => (
    is     => 'rw',
    coerce => sub {
        my $fields = $_[0];
        given (ref $fields) {
            when ('ARRAY') { return $fields }
            when ('HASH')  { return [keys %$fields] }
            default        { return [split ',', $fields] }
        }
    },
);

sub _build_csv {
    my ($self) = @_;
    Text::CSV->new({
        binary     => 1,
        quote_char => $self->quote_char,
        sep_char   => $self->split_char,
    });
}

sub generator {
    my ($self) = @_;
    sub {
        state $fh = $self->fh;
        state $csv = do {
            if ($self->header) {
                if ($self->fields) {
                    $self->csv->getline($fh);
                } else {
                    $self->fields($self->csv->getline($fh));
                }
            }
            $self->csv->column_names($self->fields);
            $self->csv;
        };
        $csv->getline_hr($fh);
    };
}

1;
