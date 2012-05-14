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
        'Dancer' => '1.3094', # Dancer::Plugin::*
        'Data::Compare' => '1.22',
        'Data::MessagePack' => '0.39',
        'Data::SpreadPagination' => '0.1.2',
        'Data::Visitor::Callback' => '0.28', # Catmandu::Store::Hash
        'Data::UUID' => '1.217',
        'Data::Util' => '0.59',
        'DateTime' => '0.70',
        'DBI' => '1.616', # Catmandu::Store::DBI
        'ElasticSearch' => '0.50', # Catmandu::Store::ElasticSearch
        'IO::String' => '1.08',
        'JSON' => '2.51',
        'LaTeX::Encode' => '0.03', # Catmandu::Exporter::BibTeX
        'Moo' => '0.091004',
        'Plack' => '0.9982',
        'Plack::Middleware::Session' => '0.14', # Plack::Session::Store::Catmandu
        'Spreadsheet::WriteExcel' => '2.37', # Catmandu::Exporter::XLS
        'SRU' => '0.99', # Dancer::Plugin::Catmandu::SRU
        'Sub::Exporter' => '0.982',
        'Template' => '2.22',
        'Text::CSV' => '1.21',
        'WebService::Solr' => '0.16', # Catmandu::Store::Solr
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
