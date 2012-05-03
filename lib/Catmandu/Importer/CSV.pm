package Catmandu::Importer::CSV;

use Catmandu::Sane;
use Moo;
use Text::CSV;

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

=head1 METHODS

=head2 new(file => $filename, fields => \@fields, quote_char => "\"", sep_char => ",")

Create a new CSV importer for $filename. Use STDIN when no filename is given. The
object fields are read from the CSV header line or given via the 'fields' parameter.
Strings in CSV are quoted by 'quote_char' and fields are separated by 'sep_char'.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::CSV methods are not idempotent: CSV streams can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
