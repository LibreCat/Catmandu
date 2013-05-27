package Catmandu::Exporter::CSV;

use namespace::clean;
use Catmandu::Sane;
use Text::CSV;
use Moo;

with 'Catmandu::Exporter';

has csv         => (is => 'ro', lazy => 1, builder => '_build_csv');
has sep_char    => (is => 'ro', default => sub { ',' });
has quote_char  => (is => 'ro', default => sub { '"' });
has escape_char => (is => 'ro', default => sub { '"' });
has header      => (is => 'rw', default => sub { 1 });
has fields => (
    is     => 'rw',
    coerce => sub {
        my $fields = $_[0];
        if (ref $fields eq 'ARRAY') { return $fields }
        if (ref $fields eq 'HASH')  { return [keys %$fields] }
        return [split ',', $fields];
    },
);

sub _build_csv {
    my ($self) = @_;
    Text::CSV->new({
        binary => 1,
        eol => "\n",
        sep_char => $self->sep_char,
        quote_char => $self->quote_char ? $self->quote_char : undef,
        escape_char => $self->escape_char ? $self->escape_char : undef,
    });
}

sub add {
    my ($self, $data) = @_;
    my $fields = $self->fields || $self->fields($data);
    my $row = [map {
        my $val = $data->{$_} // "";
        $val =~ s/\t/\\t/g;
        $val =~ s/\n/\\n/g;
        $val =~ s/\r/\\r/g;
        $val;
    } @$fields];
    my $fh = $self->fh;
    if ($self->count == 0 && $self->header) {
        $self->csv->print($fh, ref $self->header
            ? [map { $self->header->{$_} // $_ } @$fields]
            : $fields);
    }
    $self->csv->print($fh, $row);
}

=head1 NAME

Catmandu::Exporter::CSV - a CSV exporter

=head1 SYNOPSIS

    use Catmandu::Exporter::CSV;

    my $exporter = Catmandu::Exporter::CSV->new(
				fix => 'myfix.txt'
				quote_char => '"' ,
				sep_char => ',' ,
				header => 1);

    $exporter->fields("f1,f2,f3");
    $exporter->fields([qw(f1 f2 f3)]);

    # add custom header labels
    $exporter->header({f2 => 'field two'});

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d objects\n" , $exporter->count;

=head1 METHODS

=head2 new(quote_char => STRING, sep_char => STRING, header => 0|1|HASH, fields => ARRAY|HASH|STRING)

Creates a new Catmandu::Exporter::CSV. Optionally set the field and column
boundaries with quote_char and sep_char. A header line with field names will be
included if C<header> is set. Field names can be read from the first item
exported or set by the fields argument (see: C<fields>).

=head2 fields($arrayref)

Set the field names by an ARRAY reference.

=head2 fields($hashref)

Set the field names by the keys of a HASH reference.

=head2 fields($string)

Set the fields by a comma delimited string.

=head2 header(1)

Include a header line with the field names

=head2 header($hashref)

Include a header line with custom field names

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

1;
