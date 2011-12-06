package Catmandu::Fix::expand;

use Catmandu::Sane;
use Moo;
use CGI::Expand qw(expand_hash);

sub fix {
    expand_hash $_[1];
}

1;
