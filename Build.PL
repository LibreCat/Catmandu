use strict;
use warnings;
use Module::Build;

my $build_requires = {
    'Software::License' => 0,
    'Test::Exception' => '0.31',
};

my $requires = {
    'perl' => '5.10.0',
    'all' => '0.5101',
    'App::Cmd' => '0.310',
    'CGI::Expand' => '2.02',
    'Clone' => '0.31',
    'Dancer' => '1.3080',
    'Data::Compare' => '1.22',
    'Data::MessagePack' => '0.39',
    'Data::SpreadPagination' => '0.1.2',
    'Data::UUID' => '1.217',
    'Data::Util' => '0.59',
    'DateTime' => '0.70',
    'File::Path' => '2.07',
    'File::Slurp' => '9999.13',
    'IO::String' => '1.08',
    'JSON' => '2.51',
    'Moo' => '0.009011',
    'Plack' => '0.9982',
    'Template' => '2.22',
    'Time::HiRes' => '1.9724',
    'YAML::Any' => '0.77',
};

my $recommends = {
    'JSON::XS' => '2.3',
    'YAML::XS' => '0.34',
};

my $auto_features = {
    cmd_repl => {
        description => "REPL",
        requires => {
            'Devel::REPL' => '1.003012',
        },
    },
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
    store_elasticsearch => {
        description => "Searchable store backed by ElasticSearch",
        requires => {
            'ElasticSearch' => '0.47',
        },
    },
    store_lucy => {
        description => "Searchable store backed by Lucy",
        requires => {
            'Lucy' => '0.2.2',
        },
    },
    store_solr => {
        description => "Searchable store backed by Solr",
        requires => {
            'WebService::Solr' => '0.16',
        },
    },
    import_atom => {
        description => "Import data from an Atom feed",
        requires => {
            'XML::Atom' => '0.41',
        },
    },
    import_csv => {
        description => "Import data from a CSV file",
        requires => {
            'Text::CSV' => '1.21',
        },
    },
    import_oai => {
        description => "Import data from an OAI harvestable respository",
        requires => {
            'Net::OAI::Harvester' => '1.13',
        },
    },
    import_marc => {
        description => "Import data from MARC",
        requires => {
            'MARC::Record' => '2.0.3',
        },
    },
    export_bibtex => {
        description => "Export data to BibTeX",
        requires => {
            'LaTeX::Encode' => '0.03',
        },
    },
    export_csv => {
        description => "Export data to CSV",
        requires => {
            'Text::CSV' => '1.21',
        },
    },
    export_xls => {
        description => "Export data to Excel (.xls)",
        requires => {
            'Spreadsheet::WriteExcel' => '2.37',
        },
    },
    tt_language_name => {
        description => "Template filter to lookup the name for a ISO639-1 or ISO639-2 language code",
        requires => {
            'Locale::Codes::Language' => '3.18',
        },
    },
    plack_session_catmandu => {
        description => "use a Catmandu store as Plack session store",
        requires => {
            'Plack::Middleware::Session' => '0.14',
        },
    },
    dancer_plugin_ldap => {
        description => "Dancer LDAP plugin",
        requires => {
            'Net::LDAP' => '0.43',
        },
    },
    dancer_plugin_locale_detect => {
        description => "Dancer plugin to detect and set the current locale",
        requires => {
            'Locale::Util' => 0,
        },
    },
    dancer_plugin_locale_textdomain => {
        description => "Dancer i18n plugin",
        requires => {
            'Locale::TextDomain' => '1.20',
        },
    },
    dancer_plugin_multivalue_params => {
        description => "Dancer plugin to access params as a Hash::MultiValue",
        requires => {
            'Hash::MultiValue' => '0.10',
        },
    },
    dancer_plugin_nested_params => {
        description => "Dancer plugin to access expand flattened params in TT dot notation",
        requires => {
            'CGI::Expand' => '2.03',
        },
    },
    dancer_plugin_sru => {
        description => "Dancer plugin to act as SRU provider",
        requires => {
            'SRU' => '0.99',
        },
    },
};

my $build = Module::Build->new(
    module_name => 'Catmandu',
    license => 'perl',
    dist_author => [
        'Nicolas Steenlant <nicolas.steenlant@ugent.be>',
        'Patrick Hochstenbach <patrick.hochstenbach@ugent.be>',
    ],
    build_requires => $build_requires,
    requires => $requires,
    recommends => $recommends,
    auto_features => $auto_features,
    create_license => 1,
);

for my $feature (keys %$auto_features) {
    next if $build->feature($feature);
    my $enable = $build->prompt("enable feature $feature?");
    if ($enable =~ /^y/i) {
        my $feature_requires = $auto_features->{$feature}{requires};
        for my $key (keys %$feature_requires) {
            $build->requires->{$key} = $feature_requires->{$key};
        }
        $build->feature($feature => 1);
    } else {
        $build->feature($feature => 0);
    }
}

$build->create_build_script;
