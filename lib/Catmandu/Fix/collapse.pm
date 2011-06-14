package Catmandu::Fix::collapse;
use Catmandu::Sane;
use Catmandu::Object;
use CGI::Expand qw(collapse_hash);

sub fix {
    collapse_hash $_[1];
}

1;
