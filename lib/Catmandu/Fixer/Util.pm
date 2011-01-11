package Catmandu::Fixer::Util;

use Carp ();
use JSON::Path;
use Sub::Exporter -setup => {
    exports => [qw(
        path_and_field
        path_values
    )],
};

sub path_and_field {
    my $arg = pop;

    Carp::confess "Not a JSONPath" if ref $arg ne 'JSON::Path';

    my ($path, $field) = ($arg->to_string =~ /(.+)\.(\w+)$/) or
        Carp::confess "JSONPath doesn't point to a field";

    if ($path eq '$') {
        $path = undef;
    } else {
        $path = JSON::Path->new($path);
    }

    return $path, $field;
}

sub path_values {
    my $path = pop;
    my $obj  = pop;
    return $obj                if not $path; # root path
    return $path->values($obj) if ref $path; # path
    return $path;                            # scalar
}

1;

