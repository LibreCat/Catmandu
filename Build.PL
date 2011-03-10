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
        'Data::UUID' => '1.217',
        'File::Slurp' => '9999.13 ',
        'Hash::MultiValue' => '0.08',
        'IO::String' => '1.08',
        'IO::YAML' => '0.08',
        'JSON' => '2.51',
        'JSON::Path' => '0.100',
        'Plack' => '0.9974',
        'Plack::Middleware::Session' => '0.13',
        'Template' => '2.22',
        'YAML' => '0.72',
    },

    recommends => {
        'JSON::XS' => '2.3',
        'YAML::XS' => '0.34',
    },

    auto_features => {
        app_plugin_locale => {
            description => "App localization support",
            requires => {
                'Locale::TextDomain' => '1.20',
            },
        },
        template_plugin_locale => {
            description => "Template localization support",
            requires => {
                'Locale::TextDomain' => '1.20',
            },
        },
        store_sqlite => {
            description => "Store backed by SQLite",
            requires => {
                'DBD::SQLite' => '1.31',
            },
        },
        store_mongodb => {
            description => "Store backed by MongoDB",
            requires => {
                'MongoDB' => '0.42',
            },
        },
        store_plugin_timestamps => {
            description => "Timestamp stored objects",
            requires => {
                'DateTime' => '0.66',
            },
        },
        index_kinosearch => {
            description => "Index backed by Kinosearch",
            requires => {
                'KinoSearch' => '0.31',
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
    }
);

$build->create_build_script;
