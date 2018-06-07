package Catmandu::Fix::Namespace::python;

use Catmandu::Sane;

our $VERSION = '1.09';

use Inline::Python qw(py_eval);
use String::CamelCase qw(camelize);
use Moo;
use namespace::clean;

with 'Catmandu::Fix::Namespace';

sub load {
    my ($self, $name, $args, $type) = @_;
    if ($type) {
        Catmandu::NotImplemented->throw("$type fixes cannot yet be loaded from Python");
    }
    my $py_pkg = $self->name;
    my $py_class = camelize($name);
    py_eval("import $py_pkg");
    Inline::Python::Object->new($py_pkg, $py_class);
}

1;
