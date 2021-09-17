package Catmandu::Importer::CSV;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Text::CSV;
use List::Util qw(reduce);
use Moo;
use namespace::clean;

with 'Catmandu::Importer';

has csv      => (is => 'ro', lazy => 1, builder => '_build_csv');
has sep_char => (
    is      => 'ro',
    default => sub {','},
    coerce  => sub {
        my $sep_char = $_[0];
        $sep_char =~ s/(\\[abefnrt])/"qq{$1}"/gee;
        return $sep_char;
    }
);
has quote_char          => (is => 'ro', default => sub {'"'});
has escape_char         => (is => 'ro', default => sub {'"'});
has allow_loose_quotes  => (is => 'ro', default => sub {0});
has allow_loose_escapes => (is => 'ro', default => sub {0});
has header              => (is => 'ro', default => sub {1});
has fields              => (
    is     => 'rwp',
    coerce => sub {
        my $fields = $_[0];
        if (ref $fields eq 'ARRAY') {return $fields}
        if (ref $fields eq 'HASH')  {return [sort keys %$fields]}
        return [split ',', $fields];
    },
);

sub _build_csv {
    my ($self) = @_;
    Text::CSV->new(
        {
            binary      => 1,
            sep_char    => $self->sep_char,
            quote_char  => $self->quote_char ? $self->quote_char : undef,
            escape_char => $self->escape_char ? $self->escape_char : undef,
            allow_loose_quotes  => $self->allow_loose_quotes,
            allow_loose_escapes => $self->allow_loose_escapes,
        }
    );
}

sub generator {
    my ($self) = @_;
    sub {
        state $line = 0;
        state $fh   = $self->fh;
        state $csv  = do {
            if ($self->header) {
                if ($self->fields) {
                    $self->csv->getline($fh);
                    $line++;
                }
                else {
                    $self->_set_fields($self->csv->getline($fh));
                    $line++;
                }
            }
            if ($self->fields) {
                $self->csv->column_names($self->fields);
            }
            $self->csv;
        };

        # generate field names if needed
        unless ($self->fields) {
            my $row = $csv->getline($fh) // return;
            $line++;
            my $fields = [0 .. (@$row - 1)];
            $self->_set_fields($fields);
            $csv->column_names($fields);
            return reduce {
                $a->{$b} = $row->[$b] if length $row->[$b];
                $a;
            }
            +{}, @$fields;
        }

        my $rec = $csv->getline_hr($fh);
        $line++;

        if (defined $rec || $csv->eof()) {
            return $rec;
        }
        else {
            my ($cde, $str, $pos) = $csv->error_diag();
            die
                "at line $line (byte $pos) found a Text::CSV parse error($cde) $str";
        }
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::CSV - Package that imports CSV data

=head1 SYNOPSIS

    # From the command line

    # convert a CSV file to JSON
    catmandu convert CSV to JSON < journals.csv

    # set column names if CSV file has no header line
    echo '12157,"The Journal of Headache and Pain",2193-1801' | \
      catmandu convert CSV --header 0 --fields 'id,title,issn' to YAML
    
    # set field separator and quote character 
    echo '12157;$The Journal of Headache and Pain$;2193-1801' | \
      catmandu convert CSV --header 0 --fields 'id,title,issn' --sep_char ';' --quote_char '$' to XLSX --file journal.xlsx

    # In a Perl script

    use Catmandu;

    my $importer = Catmandu->importer('CSV', file => "/foo/bar.csv");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 DESCRIPTION

The package imports comma-separated values (CSV).  The object
fields are read from the CSV header line or given via the C<fields> parameter.
Strings in CSV are quoted by C<quote_char> and fields are separated by
C<sep_char>.

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=item fields

List of fields to be used as columns, given as array reference, comma-separated
string, or hash reference. If C<header> is C<0> and C<fields> is C<undef> the
fields will be named by column index ("0", "1", "2", ...).

=item header

Read fields from a header line with the column names, if set to C<1> (the
default).

=item sep_char

Column separator (C<,> by default)

=item quote_char

Quotation character (C<"> by default)

=item escape_char

Character for escaping inside quoted field (C<"> by default)

=item allow_loose_quotes

=item allow_loose_escapes

Allow common bad-practice in CSV escaping

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.  The methods are not idempotent: CSV streams can only be read once.

=head1 SEE ALSO

L<Catmandu::Exporter::CSV>, L<Catmandu::Importer::XLS>

=cut
