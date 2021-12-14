package Catmandu::Exporter::CSV;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Text::CSV;
use Moo;
use namespace::clean;

with 'Catmandu::TabularExporter';

has csv          => (is => 'lazy');
has quote_char   => (is => 'ro', default => sub {'"'});
has escape_char  => (is => 'ro', default => sub {'"'});
has always_quote => (is => 'ro');
has quote_space  => (is => 'ro');
has sep_char => (
    is      => 'ro',
    default => sub {','},
    coerce  => sub {
        my $sep_char = $_[0];
        $sep_char =~ s/(\\[abefnrt])/"qq{$1}"/gee;
        return $sep_char;
    }
);

sub _build_csv {
    my ($self) = @_;
    Text::CSV->new(
        {
            binary       => 1,
            eol          => "\n",
            sep_char     => $self->sep_char,
            always_quote => $self->always_quote,
            quote_space  => $self->quote_space,
            quote_char   => $self->quote_char  ? $self->quote_char  : undef,
            escape_char  => $self->escape_char ? $self->escape_char : undef,
        }
    );
}

sub add {
    my ($self, $data) = @_;
    my $fields = $self->fields;
    my $row    = [
        map {
            my $val = $data->{$_} // "";
            $val =~ s/\t/\\t/g;
            $val =~ s/\n/\\n/g;
            $val =~ s/\r/\\r/g;
            $val;
        } @$fields
    ];

    $self->_print_header;
    $self->csv->print($self->fh, $row);
}

sub commit {
    my ($self) = @_;

    # ensure header gets printed even if there are no records
    $self->_print_header;
}

sub _print_header {
    my ($self) = @_;
    if (!$self->count && $self->header) {
        my $row = $self->columns || $self->fields;
        $self->csv->print($self->fh, $row) if $row && @$row;
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::CSV - a CSV exporter

=head1 SYNOPSIS

    # On the command line

    $ catmandu convert XSL to CSV < data.xls

    $ catmandu convert JSON to CSV --fix myfixes.txt --sep_char ';' < data.json

    # In a Perl script

    use Catmandu;

    my $exporter = Catmandu->exporter('CSV',
                fix => 'myfix.txt',
                quote_char => '"',
                sep_char => ',',
                escape_char => '"' ,
                always_quote => 1,
                header => 1);

    $exporter->fields("f1,f2,f3");
    $exporter->fields([qw(f1 f2 f3)]);

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d items\n" , $exporter->count;

=head1 DESCRIPTION

This C<Catmandu::Exporter> exports items as rows with comma-separated values
(CSV). Serialization is based on L<Text::CSV>. A header line with field names
will be included if option C<header> is set. See L<Catmandu::TabularExporter>
on how to configure the field mapping and column names. Newlines and tabulator
values in field values are escaped as C<\n>, C<\r>, and C<\t>.

=head1 CONFIGURATION

=over

=item file

Write output to a local file given by its path or file handle.  Alternatively a
scalar reference can be passed to write to a string and a code reference can be
used to write to a callback function.

=item fh

Write the output to an L<IO::Handle>. If not specified,
L<Catmandu::Util::io|Catmandu::Util/IO-functions> is used to create the output
handle from the C<file> argument or by using STDOUT.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to exported items.

=item encoding

Binmode of the output stream C<fh>. Set to "C<:utf8>" by default.

=item sep_char

Column separator (C<,> by default)

=item quote_char

Quotation character (C<"> by default)

=item escape_char

Character for escaping inside quoted field (C<"> by default)

=item fields

See L<Catmandu::TabularExporter>.

=item columns

See L<Catmandu::TabularExporter>.

=item header

Include a header line with column names. Enabled by default.

=back

=head1 METHODS

See L<Catmandu::TabularExporter>, L<Catmandu::Exporter>, L<Catmandu::Addable>,
L<Catmandu::Fixable>, L<Catmandu::Counter>, and L<Catmandu::Logger> for a full
list of methods.

=head1 SEE ALSO

L<Catmandu::Importer::CSV>, L<Catmandu::Exporter::Table>
L<Catmandu::Exporter::XLS>

=cut
