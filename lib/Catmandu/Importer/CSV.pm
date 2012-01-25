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

=head1 NAME

Catmandu::Importer::CSV - Package that imports CSV data

=head1 SYNOPSIS

    use Catmandu::Importer::CSV;

    my $importer = Catmandu::Importer::CSV->new(file => "/foo/bar.csv");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new(file => $filename, fields => \@fields, quote_char => "\"", split_char => ",")

Create a new CSV importer for $filename. Use STDIN when no filename is given. The
object fields are read from the CSV header line or given via the 'fields' parameter.
Strings in CSV are quoted by 'quote_char' and fields are split by 'split_char'.

=head2 each(&callback)

The each method imports the data and executes the callback function for
each item imported. Returns the number of items imported or undef on 
failure.

=cut

1;
