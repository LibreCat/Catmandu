package Catmandu::App;

use Any::Moose '::Exporter';
use Any::Moose '::Util' => ['apply_all_roles'];
use Catmandu::App::Role;

any_moose('::Exporter')->setup_import_methods(also => any_moose,
    as_is => [qw(any get put post delete)]);

sub init_meta {
    shift;
    my $meta = any_moose->init_meta(@_);
    my %args = @_;
    apply_all_roles($args{for_class}, 'Catmandu::App::Role');
    $meta;
}

sub any    { caller(0)->on_any(@_) }
sub get    { caller(0)->on_get(@_) }
sub put    { caller(0)->on_put(@_) }
sub post   { caller(0)->on_post(@_) }
sub delete { caller(0)->on_delete(@_) }

no Any::Moose '::Util';
__PACKAGE__;

