package Catmandu::Fixer::Util;
# VERSION
use Exporter qw(import);
use JSON::Path;
use Carp ();

@EXPORT_OK = qw(
    path_and_field
    path_values
);

sub path_and_field {
    my $arg = pop;

    Carp::confess "Not a JSONPath" unless ref $arg eq 'JSON::Path';

    # should match $.foo.bar, $.foo['bar'] or $.foo["bar"]
    my ($path, $b1, $field , $b2) = ($arg->to_string =~ /(.+)(\.|\[['"])([^'"\.]+)(['"]\])?$/) or
        Carp::confess "JSONPath doesn't point to a field";

    if ($path eq '$') {
        $path = undef;
    } else {
        $path = JSON::Path->new($path);
    }

    return $path, $field;
}

sub path_values {
    my ($obj,$path_or_value) = @_;

    return $obj                         if not $path_or_value; # root path
    return $path_or_value->values($obj) if ref $path_or_value eq 'JSON::Path'; # path
    return $path_or_value;                                     # value 
}

1;

