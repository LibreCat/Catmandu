package Catmandu::Fix::Builder;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Catmandu::Fix;
use Catmandu::Util qw(is_value require_package);
use Moo::Role;
use namespace::clean;

with 'Catmandu::Logger';

requires '_build_fixer';

has fixer => (is => 'lazy');

sub fix {
    my ($self, $data) = @_;
    $self->fixer->($data);
}

sub _as_path {
    my ($self, $path) = @_;
    if (is_value($path)) {
        require_package('default', 'Catmandu::Path')->new(path => $path);
    }
    else {
        $path;
    }
}

sub _escape_regex {
    my ($self, $str) = @_;
    $str =~ s/\//\\\//g;
    $str =~ s/\\$/\\\\/;    # pattern can't end with an escape
    $str;
}

sub _regex {
    my ($self, $str) = @_;
    $str = $self->_escape_regex($str);
    qr/$str/;
}

sub _substituter {
    my ($self, $search, $replace) = @_;
    $search  = $self->_regex($search);
    $replace = $self->_escape_regex($replace);
    use warnings FATAL => 'all';
    eval
        qq|sub {my \$str = \$_[0]; utf8::upgrade(\$str); \$str =~ s/$search/$replace/g; \$str}|;
}

1;
