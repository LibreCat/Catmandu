use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok 'Catmandu::Importer::Modules';
require_ok 'Catmandu::Importer::Modules';

my @modules;

ok Catmandu::Importer::Modules->new->first, 'default importer';

lives_ok sub {
    @modules = @{Catmandu::Importer::Modules->new(
            inc       => ["lib"],
            namespace => "Catmandu::Fix",
            max_depth => 1,
            pattern   => qr/add_field/
        )->to_array
    };
};

ok @modules > 0, 'imported with options';
is $modules[0]->{name}, 'Catmandu::Fix::add_field', 'name';
like $modules[0]->{about}, qr/^add or change the value of a HASH key/,
    'about';

lives_ok sub {
    @modules = @{Catmandu::Importer::Modules->new(
            inc       => ["lib"],
            namespace => "Catmandu::Importer,Catmandu::Exporter",
            max_depth => 1,
            pattern   => qr/JSON/,
            about     => 0,
        )->to_array
    };
};

is_deeply [map {$_->{name}} @modules],
    [qw(Catmandu::Importer::JSON Catmandu::Exporter::JSON)],
    "multiple namespaces";

is $modules[0]->{about}, undef, 'disable about';

done_testing;
