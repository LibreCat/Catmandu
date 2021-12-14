package Catmandu::Importer::TSV;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Catmandu::Importer::CSV;
use Moo;
use namespace::clean;

with 'Catmandu::Importer';

has header => (is => 'ro', default => sub {1});
has sep_char => (
    is      => 'ro',
    default => sub {"\t"},
    coerce  => sub {
        my $sep_char = $_[0];
        $sep_char =~ s/(\\[abefnrt])/"qq{$1}"/gee;
        return $sep_char;
    }
);
has fields => (
    is     => 'rwp',
    coerce => sub {
        my $fields = $_[0];
        if (ref $fields eq 'ARRAY') {return $fields}
        if (ref $fields eq 'HASH')  {return [sort keys %$fields]}
        return [split ',', $fields];
    },
);

has csv => (is => 'lazy');

sub _build_csv {
    my ($self) = @_;
    my $csv = Catmandu::Importer::CSV->new(
        header      => $self->header,
        sep_char    => $self->sep_char,
        quote_char  => undef,
        escape_char => undef,
        file        => $self->file,
    );
    $csv->{fields} = $self->fields;
    $csv;
}

sub generator {
    my ($self) = @_;
    $self->csv->generator;
}

1;

__END__
=pod

=head1 NAME

Catmandu::Importer::TSV - Package that imports tab-separated values

=head1 SYNOPSIS

    # From the command line

    # convert a TSV file to JSON
    catmandu convert TSV to JSON < journals.tab

    # Or in a Perl script

    use Catmandu;

    my $importer = Catmandu->importer('TSV', file => "/foo/bar.tab");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 DESCRIPTION

This package imports tab-separated values (TSV).  The object
fields are read from the TSV header line or given via the C<fields> parameter.

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

Column separator (C<tab> by default)

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.  The methods are not idempotent: CSV streams can only be read once.

=head1 SEE ALSO

L<Catmandu::Exporter::TSV>

=cut
