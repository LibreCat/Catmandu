package Catmandu::Exporter::CSV;

use namespace::clean;
use Catmandu::Sane;
use Text::CSV;
use Moo;

with 'Catmandu::Exporter';

has csv          => (is => 'ro', lazy => 1, builder => 1);
has sep_char     => (is => 'ro', default => sub { ',' });
has quote_char   => (is => 'ro', default => sub { '"' });
has escape_char  => (is => 'ro', default => sub { '"' });
has always_quote => (is => 'ro');
has header       => (is => 'lazy', default => sub { 1 });

has fields => (
    is      => 'rw',
    trigger => sub {
        my ($self, $fields) = @_;
        $self->{fields} = _coerce_list($fields);
        if (ref $fields and ref $fields eq 'HASH') {
            $self->{header} = [
                map { $fields->{$_} // $_ } @{$self->{fields}} 
            ];
        }
    },
);

sub _coerce_list {
    my $fields = $_[0];
    if (ref $fields eq 'ARRAY') { return $fields }
    if (ref $fields eq 'HASH')  { return [sort keys %$fields] }
    return [split ',', $fields];
}

sub _build_csv {
    my ($self) = @_;
    Text::CSV->new({
        binary => 1,
        eol => "\n",
        sep_char => $self->sep_char,
        always_quote => $self->always_quote,        
        quote_char => $self->quote_char ? $self->quote_char : undef,
        escape_char => $self->escape_char ? $self->escape_char : undef,
    });
}

sub add {
    my ($self, $data) = @_;
    return undef unless defined $data;
    $self->fields([ sort keys %$data ]) unless $self->fields;
    my $fields = $self->fields;
    my $row = [map {
        my $val = $data->{$_} // "";
        $val =~ s/\t/\\t/g;
        $val =~ s/\n/\\n/g;
        $val =~ s/\r/\\r/g;
        $val;
    } @$fields];
    my $fh = $self->fh;
    # We need to wait for the first row that can be printed to provide us
    # with an header...
    if (!defined($self->{__seen_header__}) && $self->header) {
        $self->csv->print($fh, ref $self->header ? $self->header : $fields);
    }
    $self->{__seen_header__} = 1;
    $self->csv->print($fh, $row);
}

=head1 NAME

Catmandu::Exporter::CSV - a CSV exporter

=head1 SYNOPSIS

    use Catmandu::Exporter::CSV;

    my $exporter = Catmandu::Exporter::CSV->new(
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

    printf "exported %d objects\n" , $exporter->count;

=head1 DESCRIPTION

This C<Catmandu::Exporter> exports items as rows with comma-separated values
(CSV). Serialization is based on L<Text::CSV>. A header line with field names
will be included if option C<header> is set. Field names can be read from the
first item exported or set by option C<fields>. Newlines and tabulator values
are in field values are escaped as C<\n>, C<\r>, and C<\t>.

=head1 CONFIGURATION

=over 4

=item sep_char

Column separator (C<,> by default>)

=item quote_char

Quotation character (C<"> by default>)

=item escape_char

Character for escaping inside quoted field (C<"> by default)

=item fields

List of fields to be used as columns, given as array reference, comma-separated
string, or hash reference.

=item header

Include a header line with the column names, if set to C<1> (the default).
Custom field names can be supplied as has reference. By default field names
are used as as column names.

=back

=head1 METHODS

See L<Catmandu::Exporter>, L<Catmandu::Addable>, L<Catmandu::Fixable>,
L<Catmandu::Counter>, and L<Catmandu::Logger> for a full list of methods.

=head1 SEE ALSO

L<Catmandu::Exporter::Table>

=cut

1;
