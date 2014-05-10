package Catmandu::Importer::Importers;
use Catmandu::Sane;
use Moo;
use Catmandu::Importer::Module::Info;

with 'Catmandu::Importer';

has local => (
    is => 'ro',
    default => sub { 1; }
);

sub generator {
    my ($self) = @_;
    sub {
        state $loaded = 0;
        state $modules = [];

        unless($loaded){
            $modules = Catmandu::Importer::Module::Info->new(
                local => $self->local,
                namespace => "Catmandu::Importer",
                max_depth => 3
            )->to_array();
            $loaded = 1;
        }

        shift @$modules;

    };
}

1;
