package Catmandu::Util::Path;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Util qw(is_value is_string require_package);
use namespace::clean;
use Exporter qw(import);

our @EXPORT_OK = qw(
    looks_like_path
    as_path
);

our %EXPORT_TAGS = (all => \@EXPORT_OK,);

sub looks_like_path {    # TODO only recognizes Catmandu::Path::simple
    my ($path) = @_;
    is_string($path) && $path =~ /^\$[\.\/]/ ? 1 : 0;
}

sub as_path {
    my ($path, $path_type) = @_;
    if (is_value($path)) {
        $path_type //= 'simple';
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

__END__

=pod

=head1 NAME

Catmandu::Util::Path - Path related utility functions

=head1 FUNCTIONS

=over 4

=item looks_like_path($str)

Returns 1 if the given string is a path, 0 otherwise.  Only recognizes
L<Catmandu::Path::simple> paths prefixed with a dollar sign at the moment.

    looks_like_path("$.foo.bar.$append")
    # => 1
    looks_like_path("waffles")
    # => 0

=item as_path($str, $type)

Helper function that returns a L<Catmandu::Path> instance for the given path
string.  The optional C<$type> argument gives preliminary support for
alternative path implementations and defaults to 'simple'.

    as_path("$.foo.bar.$append")
    # is equivalent to
    Catmandu::Path::simple->new(path => "$.foo.bar.$append");

=back

=cut
