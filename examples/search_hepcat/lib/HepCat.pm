package HepCat;
use Dancer ':syntax';

our $VERSION = '0.1';

use Module::Pluggable require => 1, search_path => ['HepCat::Controller'];
plugins;

1;
