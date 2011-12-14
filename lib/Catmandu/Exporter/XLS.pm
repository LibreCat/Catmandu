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
    1;
}

1;
