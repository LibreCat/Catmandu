package Catmandu::Exporter::XLS;
use Catmandu::Sane;
use Catmandu::Util qw(io quacks);
use Spreadsheet::WriteExcel;
use Catmandu::Object file => { default => sub { *STDOUT } }, fields => 'r';

sub _set_fields {
    my ($self, $fields) = @_;

    if (!ref $fields) {
        [ split $self->split_char, $fields ];
    } elsif (ref $fields eq 'HASH') {
        [ keys %$fields ];
    } elsif (ref $fields eq 'ARRAY') {
        $fields;
    }
}

sub _build {
    my ($self, $args) = @_;
    $self->SUPER::_build($args);
    if ($self->fields) {
        $self->_set_fields($self->fields);
    }
}

sub add {
    my ($self, $obj) = @_;

    my $xls = Spreadsheet::WriteExcel->new(io($self->file, 'w'));
    my $sheet = $xls->add_worksheet;

    my $fields = $self->fields;

    my $n = 0;

    if ($fields) {
        for (my $i = 0; $i < @$fields; $i++) {
            $sheet->write_string($n, $i, $fields->[$i]);
        }
    }

    my $add = sub {
        my $o = $_[0];

        if (! $fields) {
            $fields = $self->_set_fields($o);
            for (my $i = 0; $i < @$fields; $i++) {
                $sheet->write_string($n, $i, $fields->[$i]);
            }
        }

        $n++;

        for (my $i = 0; $i < @$fields; $i++) {
            $sheet->write_string($n, $i, $o->{$fields->[$i]} // "");
        }
    };

    if (quacks $obj, 'each') {
        $obj->each($add);
        $xls->close;
        return $n;
    }

    $add->($obj);
    $xls->close;
    $n;
}

1;
