package Catmandu::Exporter::YAML;

use Catmandu::Sane;
use Moo;
use YAML::Any ();
use YAML::XS;

with 'Catmandu::Exporter';

*dump_yaml = do { no strict 'refs'; \&{YAML::Any->implementation . '::Dump'} };

sub add {
    my ($self, $data) = @_;
    my $yaml = dump_yaml($data);
    utf8::decode($yaml);
    $self->fh->print($yaml);
}

1;
