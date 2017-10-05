package Catmandu::Exporter::TSV;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Catmandu::Exporter::CSV;
use Moo;
use namespace::clean;

with 'Catmandu::TabularExporter';

has sep_char => (
    is      => 'ro',
    default => sub {"\t"},
    coerce  => sub {
        my $sep_char = $_[0];
        $sep_char =~ s/(\\[abefnrt])/"qq{$1}"/gee;
        return $sep_char;
    }
);
has csv => (is => 'lazy');

sub _build_csv {
    my ($self) = @_;
    my $csv = Catmandu::Exporter::CSV->new(
        header         => $self->header,
        collect_fields => $self->collect_fields,
        sep_char       => $self->sep_char,
        quote_char     => undef,
        escape_char    => undef,
        file           => $self->file,
    );
    $csv->{fields}  = $self->fields;
    $csv->{columns} = $self->columns;
    $csv;
}

sub add {
    my ($self, $data) = @_;
    $self->csv->add($data);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::TSV - a tab-delimited TSV exporter

=head1 SYNOPSIS

    # From the command line

    $ catmandu convert JSON to TSV --fields "id,title,year" < data.json

    # In a Perl script

    use Catmandu;

    my $exporter = Catmandu->exporter(
                'TSV',
                fix => 'myfix.txt',
                header => 1);

    $exporter->fields("f1,f2,f3");
    $exporter->fields([qw(f1 f2 f3)]);

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d objects\n" , $exporter->count;

=head1 DESCRIPTION

This C<Catmandu::Exporter> exports items as rows with tab-separated values
(TSV). A header line with field names will be included if option C<header> is
set. See L<Catmandu::TabularExporter> on how to configure the field mapping
and column names. Newlines and tabulator values in field values are escaped
as C<\n>, C<\r>, and C<\t>.

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

=item fields

See L<Catmandu::TabularExporter>.

=item columns

See L<Catmandu::TabularExporter>.

=item header

Include a header line with column names. Enabled by default.

=item sep_char

Column separator (C<tab> by default)

=back

=head1 METHODS

See L<Catmandu::TabularExporter>, L<Catmandu::Exporter>, L<Catmandu::Addable>,
L<Catmandu::Fixable>, L<Catmandu::Counter>, and L<Catmandu::Logger> for a full
list of methods.

=head1 SEE ALSO

L<Catmandu::Importer::TSV>

=cut
