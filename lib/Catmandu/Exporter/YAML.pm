package Catmandu::Exporter::YAML;

use Catmandu::Sane;
use Moo;
use YAML::Any ();
use YAML::XS; # TODO

with 'Catmandu::Exporter';

*dump_yaml = do { no strict 'refs'; \&{YAML::Any->implementation . '::Dump'} };

sub add {
    my ($self, $data) = @_;
    my $yaml = dump_yaml($data);
    utf8::decode($yaml);
    $self->fh->print($yaml);
}

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
