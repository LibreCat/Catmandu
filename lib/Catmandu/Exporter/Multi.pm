package Catmandu::Exporter::Multi;

use Catmandu::Sane;

our $VERSION = '1.06';

use Catmandu::Util qw(is_string);
use Catmandu;
use Moo;
use namespace::clean;

with 'Catmandu::Exporter';

has exporters => (
    is      => 'ro',
    default => sub {[]},
    coerce  => sub {
        my $exporters = $_[0];
        return [
            map {
                if (is_string($_)) {
                    Catmandu->exporter($_);
                }
                else {
                    $_;
                }
            } @$exporters
        ];
    },
);

sub add {
    my ($self, $data) = @_;
    $_->add($data) for @{$self->exporters};
}

sub commit {
    my ($self) = @_;
    $_->commit for @{$self->exporters};
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::Multi - export you data to multiple exporters

=head1 SYNOPSIS

    # this will write both a CSV and an XLS file
    my $exporter = Catmandu::Exporter::Multi->new(exporters => [
        Catmandu::Exporter::CSV->new(file => 'mydata.csv'),
        Catmandu::Exporter::XLS->new(file => 'mydata.xls'),
    ]);
    $exporter->add({col1 => 'val1', col2 => 'val2'});
    $exporter->commit;

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

