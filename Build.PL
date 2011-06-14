use Module::Build;

my $build = Module::Build->new(
    module_name => 'Catmandu',
    license => 'perl',
    dist_author => [
        "Nicolas Steenlant <nicolas.steenlant@ugent.be>",
        "Patrick Hochstenbach <patrick.hochstenbach@ugent.be>",
    ],

    requires => {
        'perl' => '5.10.0',
        'App::Cmd' => '0.310',
        'CGI::Expand' => '2.02',
        'Clone' => '0.31',
        'Dancer' => '1.3051',
        'Data::UUID' => '1.217',
        'File::Path' => '2.08',
        'File::Slurp' => '9999.13',
        'IO::String' => '1.08',
        'IO::YAML' => '0.08',
        'JSON' => '2.51',
        'JSON::Path' => '0.100',
        'Time::HiRes' => '1.9724',
        'YAML' => '0.72',
    },

    recommends => {
        'JSON::XS' => '2.3',
        'YAML::XS' => '0.34',
    },

    auto_features => {
        store_dbi => {
            description => "Store backed by DBI",
            requires => {
                'DBI' => '1.616',
            },
        },
        store_mongodb => {
            description => "Store backed by MongoDB",
            requires => {
                'MongoDB' => '0.42',
            },
        },
        index_lucy => {
            description => "Index backed by Lucy",
            requires => {
                'Lucy' => '0.1.0',
            },
        },
        import_csv => {
            description => "Import objects from a CSV file",
            requires => {
                'Text::CSV' => '1.21',
            },
        },
        import_spreadsheet => {
            description => "Import objects from a spreadsheet",
            requires => {
                'Spreadsheet::Read' => '0.41',
            },
        },
        import_atom => {
            description => "Import objects from an Atom feed",
            requires => {
                'XML::Atom::Client' => '0.38',
            },
        },
    }
);

$build->create_build_script;
