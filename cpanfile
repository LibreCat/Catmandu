requires 'perl', 'v5.10.1';

on 'test', sub {
  requires 'Test::Deep', 0;
  requires 'Test::Exception', 0;
  requires 'Test::More', 0;
  requires 'Log::Any::Adapter', 0;
};

requires 'App::Cmd', '0.323';
requires 'CGI::Expand', '2.02';
requires 'Clone', '0.31';
requires 'Config::Onion', '1.002';
requires 'Data::Compare', '1.22';
requires 'Data::UUID', '1.217';
requires 'Data::Util', '0.59';
requires 'IO::Handle::Util', '0.01';
requires 'JSON', '2.51';
requires 'List::MoreUtils', '0.33';
requires 'Marpa::R2', '2.084000';
requires 'Moo', '1.000008';
requires 'MooX::Log::Any', 0;
requires 'namespace::clean', '0.24';
requires 'Sub::Exporter', '0.982';
requires 'Sub::Quote', 0;
requires 'Text::CSV', '1.21';
requires 'Time::HiRes', 0, # not always installed apparently
requires 'Throwable', '0.200004';
requires 'Try::Tiny::ByClass', '0.01';
requires 'YAML::Any', '0.90';

recommends 'JSON::XS', '2.3';
recommends 'YAML::XS', '0.34';

feature 'tidy',
    "Support pretty printing compiled fix code",
    sub {
        requires 'Perl::Tidy', 0;
    };

