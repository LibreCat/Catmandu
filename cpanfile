requires 'perl', 'v5.10.1';

on 'test', sub {
  requires 'Test::Deep', '0.112';
  requires 'Test::Exception', '0.32';
  requires 'Test::More', '0.99';
  requires 'Test::Pod', 0;
  requires 'Log::Any::Test', '1.03';
  requires 'Test::LWP::UserAgent' , 0;
};

requires 'App::Cmd', '0.33';
requires 'CGI::Expand', '2.02';
requires 'Clone', '0.31';
requires 'Config::Onion', '1.004';
requires 'Data::Compare', '1.22';
requires 'Data::UUID', '1.217';
requires 'File::Find::Rule', '0.33';
requires 'File::Slurp::Tiny', '0.003';
requires 'Hash::Merge::Simple', 0;
requires 'IO::Handle::Util', '0.01';
requires 'JSON::XS', '2.3';
requires 'List::MoreUtils', '0.33';
requires 'Log::Any', '1.03';
requires 'Log::Any::Adapter', '1.03';
requires 'LWP::UserAgent', 0;
requires 'Time::Piece', 0; # undeclared Marpa dependency
requires 'Marpa::R2', '2.084000';
requires 'Module::Info', 0;
requires 'Moo', '1.004006';
requires 'MooX::Aliases', '0.001006';
requires 'namespace::clean', '0.24';
requires 'Unicode::Normalize', '0';
requires 'Sub::Exporter', '0.982';
requires 'Sub::Quote', 0;
requires 'Text::CSV', '1.21';
requires 'Time::HiRes', 0; # not always installed?
requires 'Throwable', '0.200004';
requires 'Try::Tiny::ByClass', '0.01';
requires 'URI', 0;
requires 'URI::Template', 0;
requires 'YAML::XS', '0.41';

recommends 'Log::Log4perl', '1.44';
recommends 'Log::Any::Adapter::Log4perl', '0.06';

feature 'tidy',
    "Support pretty printing compiled fix code",
    sub {
        requires 'Perl::Tidy', 0;
    };

