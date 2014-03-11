use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Catmandu',
    license => 'perl',
    dist_author => [
        'Nicolas Steenlant <nicolas.steenlant@ugent.be>',
        'Patrick Hochstenbach <patrick.hochstenbach@ugent.be>',
        'Vitali Peil <vitali.peil@uni-bielefeld.de>',
    ],
    build_requires => {
        'Test::Exception' => 0,
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.10.1',
        'App::Cmd' => '0.310',
        'CGI::Expand' => '2.02',
        'Clone' => '0.31',
        'Data::Compare' => '1.22',
        'Data::UUID' => '1.217',
        'Data::Util' => '0.59',
        'IO::Handle::Util' => '0.01',
        'JSON' => '2.51',
        'Moo' => '1.000008',
        'MooX::Log::Any' => 0,
        'namespace::clean' => '0.24',
        'Sub::Exporter' => '0.982',
        'Sub::Quote' => 0,
        'Text::CSV' => '1.21',
        'Time::HiRes' => 0, # not always installed
        'Throwable' => '0.200004',
        'Try::Tiny::ByClass' => '0.01',
        'YAML::Any' => '0.90',
    },
    recommends => {
        'JSON::XS' => '2.3',
        'YAML::XS' => '0.34',
    },
    auto_features => {
        tidy => {
            description => "Support pretty printing compiled fix code",
            requires    => {
                'Perl::Tidy' => 0,
            },
        },
    },
    add_to_cleanup => [qw(
        Catmandu-*
    )],
    create_makefile_pl => 'traditional',
    meta_merge => {
         resources => {
              repository => 'https://github.com/LibreCat/Catmandu.git',
              bugtracker => 'https://github.com/LibreCat/Catmandu/issues',
              homepage => 'https://github.com/LibreCat/Catmandu',
        },
    },
);

$build->create_build_script;
