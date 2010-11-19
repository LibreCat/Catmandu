use 5.010;
use strict;
use warnings;
use inc::Module::Install;

name         'Catmandu';
license      'perl';
perl_version '5.10.0';
version      '0.1';
include      'Module::AutoInstall';

requires 'all' => '0.5101';
requires 'CGI::Expand' => '2.02';
requires 'Data::UUID' => '1.216';
requires 'DBD::SQLite' => '1.31';
requires 'DBI' => '1.607';
requires 'Devel::REPL' => '1.003012';
requires 'File::ShareDir' => '1.02';
requires 'File::Temp' => '0.22';
requires 'Getopt::Long::Descriptive' => '0.086';
requires 'Hash::Merge' => '0.12';
requires 'HTTP::Request::Common' => '5.824';
requires 'IO::All' => '0.41';
requires 'IO::All::LWP' => '0.14';
requires 'JSON' => '2.22';
requires 'KinoSearch' => '0.31';
requires 'List::Util' => '1.23';
requires 'Moose' => '1.19';
requires 'MooseX::Daemonize' => '0.12';
requires 'MooseX::Getopt' => '0.33';
requires 'MooseX::Singleton' => '0.25';
requires 'MooseX::Types::IO' => '0.03';
requires 'Path::Class' => '0.21';
requires 'Plack' => '0.9949';
requires 'Router::Simple' => '0.07';
requires 'Template' => '2.22';
test_requires 'Test::Exception' => '0.27';
test_requires 'Test::More' => '0.94';
requires 'Try::Tiny' => '0.07';
requires 'YAML' => '0.72';

# Devel::REPL plugin dependencies
requires 'B::Keywords' => '1.10';
requires 'Data::Dumper::Concise' => '2.012';
requires 'File::Next' => '1.06';
requires 'PPI' => '1.213';
requires 'Term::ANSIColor' => '3.00';
requires 'Term::ReadLine::Perl' => '1.0303';

install_share 'share';

auto_install;

WriteAll;

