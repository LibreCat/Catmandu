package Catmandu::Exporter::YAML;

use Catmandu::Sane;
use Moo;
use YAML::Any ();

with 'Catmandu::Exporter';

*dump_yaml = do { no strict 'refs'; \&{YAML::Any->implementation . '::Dump'} };

sub add {
    my ($self, $data) = @_;
    $self->fh->print(dump_yaml($data));
}

1;
