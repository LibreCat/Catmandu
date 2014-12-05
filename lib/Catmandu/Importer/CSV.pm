package Catmandu::Importer::CSV;

use namespace::clean;
use Catmandu::Sane;
use Text::CSV;
use Moo;

with 'Catmandu::Importer';

has csv => (is => 'ro', lazy => 1, builder => '_build_csv');
has sep_char => (is => 'ro', default => sub { ',' });
has quote_char => (is => 'ro', default => sub { '"' });
has escape_char => (is => 'ro', default => sub { '"' });
has allow_loose_quotes => (is => 'ro', default => sub { 0 });
has allow_loose_escapes => (is => 'ro', default => sub { 0 });
has header => (is => 'ro', default => sub { 1 });
has fields => (
    is     => 'rw',
    coerce => sub {
        my $fields = $_[0];
        if (ref $fields eq 'ARRAY') { return $fields }
        if (ref $fields eq 'HASH')  { return [sort keys %$fields] }
        return [split ',', $fields];
    },
);

sub _build_csv {
    my ($self) = @_;
    Text::CSV->new({
        binary => 1,
        sep_char => $self->sep_char,
        quote_char => $self->quote_char ? $self->quote_char : undef,
        escape_char => $self->escape_char ? $self->escape_char : undef,
        allow_loose_quotes => $self->allow_loose_quotes,
        allow_loose_escapes => $self->allow_loose_escapes,
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

=head1 NAME

Catmandu::Importer::CSV - Package that imports CSV data

=head1 SYNOPSIS

    use Catmandu::Importer::CSV;

    my $importer = Catmandu::Importer::CSV->new(file => "/foo/bar.csv");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

Convert CSV to other formats with the catmandu command line client:

    # convert CSV file to JSON
    catmandu convert CSV to JSON < journals.csv
    # set column names if CSV file has no header line
    echo '12157,"The Journal of Headache and Pain",2193-1801' | catmandu convert CSV --header 0 --fields 'id,title,issn' to YAML
    # set field separator and quote character 
    echo '12157;$The Journal of Headache and Pain$;2193-1801' | catmandu convert CSV --header 0 --fields 'id,title,issn' --sep_char ';' --quote_char '$' to XLSX --file journal.xlsx

=head1 METHODS

=head2 new(file => $filename, fh = $fh, fields => \@fields, quote_char => "\"", sep_char => ",", fix => [...])

Create a new CSV importer for $filename. Use STDIN when no filename is given. The
object fields are read from the CSV header line or given via the 'fields' parameter.
Strings in CSV are quoted by 'quote_char' and fields are separated by 'sep_char'.

The constructor inherits the fix parameter from L<Catmandu::Fixable>. When given,
then ech fix or fix script will be applied to imported items.

=head2 count

=head2 each(&callback)

=head2 ...

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited. The Catmandu::Importer::CSV methods are not idempotent: CSV streams
can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
