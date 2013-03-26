package Catmandu::Exporter::XLS;

use namespace::clean;
use Catmandu::Sane;
use Spreadsheet::WriteExcel;
use Moo;

with 'Catmandu::Exporter';

has xls => (is => 'ro', lazy => 1, builder => '_build_xls');
has worksheet => (is => 'ro', lazy => 1, builder => '_build_worksheet');
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

sub _build_xls {
    my $xls = Spreadsheet::WriteExcel->new($_[0]->fh);
    $xls->set_properties(utf8 => 1);
    $xls;
}

sub _build_worksheet {
    $_[0]->xls->add_worksheet;
}

sub encoding { ':raw' }

sub add {
    my ($self, $data) = @_;
    my $header = $self->header;
    my $fields = $self->fields || $self->fields($data);
    my $worksheet = $self->worksheet;
    my $n = $self->count;
    if ($header) {
        if ($n == 0) {
            for (my $i = 0; $i < @$fields; $i++) {
                my $field = $fields->[$i];
                $field = $header->{$field} if ref $header && defined $header->{$field};
                $worksheet->write_string($n, $i, $field);
            }
        }
        $n++;
    }
    for (my $i = 0; $i < @$fields; $i++) {
        $worksheet->write_string($n, $i, $data->{$fields->[$i]} // "");
    }
}

sub commit {
    $_[0]->xls->close;
}

=head1 NAME

Catmandu::Exporter::XLS - a XLS exporter

=head1 SYNOPSIS

    use Catmandu::Exporter::XLS;

    my $exporter = Catmandu::Exporter::XLS->new(
				file => 'output.xls',
				fix => 'myfix.txt'
				header => 1);

    $exporter->fields("f1,f2,f3");

    # add custom header labels
    $exporter->header({f2 => 'field two'});

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    $exporter->commit;

    printf "exported %d objects\n" , $exporter->count;

=head1 METHODS

=head2 new(header => 0|1|HASH, fields => ARRAY|HASH|STRING)

Creates a new Catmandu::Exporter::XLS. A header line with field names will be
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

=head2 commit

Commit the changes and close the XLS.

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

1;
