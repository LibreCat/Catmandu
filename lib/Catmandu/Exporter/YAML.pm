package Catmandu::Exporter::YAML;

use Catmandu::Sane;
use Moo;
use YAML::Any qw(Dump);

with 'Catmandu::Exporter';

sub add {
    my ($self, $data) = @_;
    my $yaml = Dump($data);
    utf8::decode($yaml);
    $self->fh->print($yaml);
}

no YAML::Any;

=head1 NAME

Catmandu::Exporter::YAML - a YAML exporter

=head1 SYNOPSIS

    use Catmandu::Exporter::YAML;

    my $exporter = Catmandu::Exporter::YAML->new(fix => 'myfix.txt');

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d objects\n" , $exporter->count;

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

1;
