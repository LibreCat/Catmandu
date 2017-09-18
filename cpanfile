requires 'perl', 'v5.10.1';

on 'test', sub {
  requires 'Log::Any::Adapter::Log4perl', 0;
  requires 'Log::Any::Test', '1.03';
  requires 'Log::Log4perl' , 0;
  requires 'Test::Deep', '0.112';
  requires 'Test::Exception', '0.43';
  requires 'Test::LWP::UserAgent' , 0;
  requires 'Test::More', '0.99';
  requires 'Test::Pod', 0;
};

on 'develop', sub {
  requires 'Code::TidyAll', 0;
  requires 'Perl::Tidy', 0;
  requires 'Test::Code::TidyAll', '0.20';
  requires 'Text::Diff', 0; # undeclared Test::Code::TidyAll plugin dependency
  };

requires 'List::MoreUtils::XS', 0;
requires 'Any::URI::Escape', 0;
requires 'App::Cmd', '0.33';
requires 'asa', 0; # undeclared dependency?
requires 'CGI::Expand', '2.02';
requires 'Clone', '0.31';
requires 'Config::Onion', '1.004';
requires 'Cpanel::JSON::XS', '3.0213';
requires 'Data::Compare', '1.22';
requires 'Data::Util', '0.66';
requires 'Data::UUID', '1.217';
requires 'Path::Iterator::Rule','0';
requires 'Path::Tiny', '0';
requires 'Hash::Merge::Simple', 0;
requires 'IO::Handle::Util', '0.01';
requires 'List::MoreUtils', '0.33';
requires 'Log::Any', 0;
requires 'Log::Any::Adapter', 0;
requires 'LWP::UserAgent', 0;
requires 'MIME::Types',0;
requires 'Module::Info', 0;
requires 'Moo', '>=1.004006';
requires 'MooX::Aliases', '>=0.001006';
requires 'namespace::clean', '0.24';
requires 'Parser::MGC', '0.15';
requires 'Sub::Exporter', '0.982';
requires 'Sub::Quote', 0;
requires 'Text::Hogan::Compiler', '1.02';
requires 'Text::CSV', '1.21';
requires 'Time::HiRes', 0; # not always installed?
requires 'Throwable', '0.200004';
requires 'Try::Tiny::ByClass', '0.01';
requires 'Unicode::Normalize', '0';
requires 'URI', 0;
requires 'URI::Template', 0.22;
requires 'YAML::XS', '0.41';

recommends 'Log::Log4perl', '1.44';
recommends 'Log::Any::Adapter::Log4perl', '0.06';
