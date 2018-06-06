package Catmandu::Util::Path;

use Catmandu::Sane;

our $VERSION = '1.09';

use Catmandu::Util qw(is_value is_string require_package);
use namespace::clean;
use Exporter qw(import);

our @EXPORT_OK = qw(
    looks_like_path
    as_path
);

our %EXPORT_TAGS = (all => \@EXPORT_OK,);

sub looks_like_path {    # TODO only recognizes Catmandu::Path::default
    my ($path) = @_;
    is_string($path) && $path =~ /^\$[\.\/]/ ? 1 : 0;
}

sub as_path {
    my ($path, $path_type) = @_;
    if (is_value($path)) {
        $path_type //= 'default';
        state $class_cache = {};
        my $class = $class_cache->{$path_type}
            ||= require_package($path_type, 'Catmandu::Path');
        $class->new(path => $path);
    }
    else {
        $path;
    }
}

1;
