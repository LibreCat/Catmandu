package Catmandu::Util::Path;

use Catmandu::Sane;

our $VERSION = '1.09';

use Catmandu::Util qw(is_value is_string);
use Catmandu::Path::default;
use namespace::clean;
use Exporter qw(import);

our @EXPORT_OK = qw(
    looks_like_path
    as_path
);

our %EXPORT_TAGS = (all => \@EXPORT_OK,);

sub looks_like_path {
    my ($path) = @_;
    is_string($path) && $path =~ /^\$[\.\/]/ ? 1 : 0;
}

sub as_path {
    my ($path) = @_;
    if (is_value($path)) {
        Catmandu::Path::default->new(path => $path);
    }
    else {
        $path;
    }
}

1;
