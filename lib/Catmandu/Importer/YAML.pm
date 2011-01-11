package Catmandu::Importer::YAML;
# ABSTRACT: Streaming YAML importer
# VERSION
use IO::YAML;
use Moose;

with qw(Catmandu::Importer);

sub each {
    my ($self, $sub) = @_;

    my $file = IO::YAML->new($self->file, auto_load => 1);
    my $n = 0;

    while (defined(my $obj = <$file>)) {
        $sub->($obj);
        $n++;
    }

    $n;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

