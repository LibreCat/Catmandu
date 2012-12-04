use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Catmandu',
    license => 'perl',
    dist_author => [
        'Nicolas Steenlant <nicolas.steenlant@ugent.be>',
        'Patrick Hochstenbach <patrick.hochstenbach@ugent.be>',
    ],
    build_requires => {
        'Software::License' => 0,
        'Test::Exception'   => '0.31',
    },
    requires => {
        'perl' => '5.10.1',
        'App::Cmd' => '0.310',
        'CGI::Expand' => '2.02',
        'Clone' => '0.31',
        'Data::Compare' => '1.22',
        'Data::MessagePack' => '0.39',
        'Data::SpreadPagination' => '0.1.2',
        'Data::UUID' => '1.217',
        'Data::Util' => '0.59',
        'DateTime' => '0.70',
        'DBI' => '1.616', # Catmandu::Store::DBI
        'IO::String' => '1.08',
        'JSON' => '2.51',
        'LaTeX::Encode' => '0.03', # Catmandu::Exporter::BibTeX
        'Moo' => '1.0',
        'Spreadsheet::WriteExcel' => '2.37', # Catmandu::Exporter::XLS
        'Sub::Exporter' => '0.982',
        'Template' => '2.22',
        'Text::CSV' => '1.21',
        'XML::Atom' => '0.41', # Catmandu::Importer::Atom
        'YAML::Any' => '0.81',
    },
    recommends => {
        'JSON::XS' => '2.3',
        'YAML::XS' => '0.34',
    },
    add_to_cleanup => [qw(
        Catmandu-*
    )],
    create_makefile_pl => 'traditional',
    create_license => 1,
);

$build->create_build_script;
