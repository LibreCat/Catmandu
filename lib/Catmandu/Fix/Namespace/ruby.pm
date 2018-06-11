package Catmandu::Fix::Namespace::ruby;

use Catmandu::Sane;

our $VERSION = '1.09';

use Inline::Ruby qw(rb_eval rb_new_object);
use String::CamelCase qw(camelize);
use Moo;
use namespace::clean;

with 'Catmandu::Fix::Namespace';

sub load {
    my ($self, $name, $args, $type) = @_;
    if ($type) {
        Catmandu::NotImplemented->throw("$type fixes cannot yet be loaded from Ruby");
    }
    my $rb_path = $self->name;
    $rb_path =~ s/\./\//g;
    $rb_path = join('/', $rb_path, $name);
    my $rb_class = camelize($name);
    rb_eval("require '$rb_path'");
    rb_new_object($rb_path, $rb_class);
}

1;
