package Catmandu::Expander;

use Catmandu::Sane;

our $VERSION = '1.00_01';

use parent 'CGI::Expand';

sub max_array { 1000000 }

1;
