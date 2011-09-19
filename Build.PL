use strict;
use warnings;
use Module::Build;

my $requires = {
    'perl' => '5.10.0',
    'all' => '0.5101',
    'App::Cmd' => '0.310',
    'CGI::Expand' => '2.02',
    'Clone' => '0.31',
    'Dancer' => '1.3072',
    'Data::UUID' => '1.217',
    'DateTime' => '0.70',
    'File::Path' => '2.07',
    'File::Slurp' => '9999.13',
    'IO::String' => '1.08',
    'IO::YAML' => '0.08',
    'JSON' => '2.51',
    'JSON::Path' => '0.100',
    'Plack' => '0.9982',
    'Template' => '2.22',
    'Time::HiRes' => '1.9724',
    'YAML' => '0.72',
};

my $recommends = {
    'JSON::XS' => '2.3',
    'YAML::XS' => '0.34',
};

my $auto_features = {
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
    index_elasticsearch => {
        description => "Index backed by ElasticSearch",
        requires => {
            'ElasticSearch' => '0.38',
        },
    },
    index_lucy => {
        description => "Index backed by Lucy",
        requires => {
            'Lucy' => '0.1.0',
        },
    },
    index_solr => {
        description => "Index backed by Solr",
        requires => {
            'WebService::Solr' => '0.1.4',
        },
    },
    import_atom => {
        description => "Import objects from an Atom feed",
        requires => {
            'XML::Atom::Client' => 0,
        },
    },
    import_csv => {
        description => "Import objects from a CSV file",
        requires => {
            'Text::CSV' => '1.21',
        },
    },
    import_oai => {
        description => "Import objects from an OAI harvestable respository",
        requires => {
            'Net::OAI::Harvester' => '1.13',
        },
    },
    import_spreadsheet => {
        description => "Import objects from a spreadsheet",
        requires => {
            'Spreadsheet::Read' => '0.41',
        },
    },
    export_bibtex => {
        description => "Export objects to BibTeX",
        requires => {
            'LaTeX::Encode' => '0.03',
        },
    },
    export_csv => {
        description => "Export objects to CSV",
        requires => {
            'Text::CSV' => '1.21',
        },
    },
    export_xls => {
        description => "Export objects to Excel (.xls)",
        requires => {
            'Spreadsheet::WriteExcel' => '2.37',
        },
    },
    tt_language_name => {
        description => "TT filter to lookup the language name for a ISO639-1 or ISO639-2 language code",
        requires => {
            'Locale::Codes::Language' => '3.18',
        },
    },
    tt_spread_pagination => {
        description => "TT filter plugin that wraps Data::SpreadPagination",
        requires => {
            'Data::SpreadPagination' => '0.1.2',
        },
    },
    plack_session_catmandu => {
        description => "use a Catmandu store as Plack session store",
        requires => {
            'Plack::Middleware::Session' => '0.14',
        },
    },
    dancer_plugin_elasticsearch => {
        description => "Dancer ElasticSearch plugin",
        requires => {
            'ElasticSearch' => '0.38',
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
    requires => $requires,
    recommends => $recommends,
    auto_features => $auto_features,
);

for my $feature (keys %$auto_features) {
    next if $build->feature($feature);
    my $enable = $build->prompt("enable feature $feature?");
    if ($enable =~ /^y/i) {
        my $feature_requires = $auto_features->{$feature}{requires};
        $build->requires({ %$requires, %$feature_requires });
        $build->feature($feature => 1);
    }
}

$build->create_build_script;
