use 5.010;
use strict;
use warnings;
use inc::Module::Install;

name         'Catmandu';
license      'perl';
perl_version '5.10.0';
version      '0.1';
include      'Module::AutoInstall';

requires 'Any::Moose' => '0.13';
requires 'CGI::Expand' => '2.02';
requires 'Data::UUID' => '1.216';
requires 'DBM::Deep' => '2.0004';
requires 'File::ShareDir' => '1.02';
requires 'File::Slurp' => '9999.13';
requires 'File::Temp' => '0.22';
requires 'Hash::Merge' => '0.12';
requires 'HTTP::Request::Common' => '5.824';
requires 'JSON' => '2.22';
requires 'KinoSearch' => '0.31';
requires 'Path::Class' => '0.21';
requires 'Plack' => '0.9949';
requires 'Router::Simple' => '0.07';
requires 'Template' => '2.22';
test_requires 'Test::Exception' => '0.27';
test_requires 'Test::More' => '0.94';
requires 'Try::Tiny' => '0.07';
requires 'YAML' => '0.72';

install_share 'share';

auto_install;

WriteAll;

