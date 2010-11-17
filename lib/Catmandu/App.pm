package Catmandu::App;

use Moose ();
use Moose::Exporter;
use Catmandu::App::Role::Object;

Moose::Exporter->setup_import_methods(
    as_is => [qw(any get put post delete set enable enable_if mount)],
    also  => 'Moose',
);

sub init_meta {
    shift;
    my %args = @_;
    my $caller = $args{for_class};
    Moose->init_meta(%args);
    Moose::Util::apply_all_roles($caller, 'Catmandu::App::Role::Object');
    $caller->meta;
}

sub any {
    my $caller = caller;
    if (@_ == 3) {
        my ($methods, $pattern, $sub) = @_;
        $caller->add_route($pattern, $sub, method => [ map { uc $_ } @$methods ]);
    } else {
        my ($pattern, $sub) = @_;
        $caller->add_route($pattern, $sub);
    }
}

sub get { my $caller = caller; $caller->add_route(@_, method => ['GET', 'HEAD']); }
sub put { my $caller = caller; $caller->add_route(@_, method => ['PUT']); }
sub post { my $caller = caller; $caller->add_route(@_, method => ['POST']); }
sub delete { my $caller = caller; $caller->add_route(@_, method => ['DELETE']); }

sub set { my $caller = caller; $caller->stash(@_); };

sub enable { my $caller = caller; $caller->add_middleware(@_); }
sub enable_if(&$@) { my $caller = caller; $caller->add_middleware_if(@_); }
sub mount { my $caller = caller; $caller->add_mount(@_); }

__PACKAGE__;

