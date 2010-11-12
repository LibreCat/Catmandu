package Catmandu::App;

use Moose ();
use Moose::Exporter;
use Moose::Util;
use Catmandu::App::Role;

Moose::Exporter->setup_import_methods(
    as_is => [qw(any get put post delete)],
    also => 'Moose',
);

sub init_meta {
    shift;
    my $meta = Moose->init_meta(@_);
    my %args = @_;
    Moose::Util::apply_all_roles($args{for_class}, 'Catmandu::App::Role');
    $meta;
}

sub any    { caller(0)->on_any(@_) }
sub get    { caller(0)->on_get(@_) }
sub put    { caller(0)->on_put(@_) }
sub post   { caller(0)->on_post(@_) }
sub delete { caller(0)->on_delete(@_) }

__PACKAGE__;

