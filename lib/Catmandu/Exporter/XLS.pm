package Catmandu::Exporter::XLS;

use Catmandu::Sane;
use Moo;
use Spreadsheet::WriteExcel;

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
                $worksheet->write_string($n, $i, $fields->[$i]);
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

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    $exporter->commit;

    printf "exported %d objects\n" , $exporter->count;

=head1 METHODS

=head2 new(fields => ARRAY|HASH|STRING)

Creates a new Catmandu::Exporter::XLS. If header is set to 1, then a header line with field 
names will be included. Field names can be read from the first item exported or set by the 
fields argument (see: fields).

=head2 fields($arrayref)

Set the field names by an ARRAY reference.

=head2 fields($hashref)

Set the field names by the keys of a HASH reference.

=head2 fields($string)

Set the fields by a comma delimited string.

=head2 commit

Commit the changes and close the XLS.

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

1;
