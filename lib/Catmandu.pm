package Catmandu;

our $VERSION = '0.1';

use Catmandu::Sane;
use Catmandu::Util qw(load_package :check);
use Dancer qw(:syntax config);
use Exporter qw(import);

our @EXPORT_OK = qw(
    store
    importer
    exporter
);

our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $STORES = {};

sub default_store { 'default' }
sub default_importer { 'JSON' }
sub default_exporter { 'JSON' }

sub store {
    my $pkg = check_string(shift || default_store);
    $STORES->{$pkg} || do {
        if (my $cfg = check_array_ref(config->{store}{$pkg})) {
            check_string($cfg->[0]);
            check_maybe_hash_ref($cfg->[1]);
            $STORES->{$pkg} = load_package($cfg->[0], 'Catmandu::Store')->new($cfg->[1] || {});
        } else {
            load_package($pkg, 'Catmandu::Store')->new(@_);
        }
    };
}

sub importer {
    my $pkg = shift;
    load_package($pkg, 'Catmandu::Importer')->new(@_);
}

sub exporter {
    my $pkg = shift;
    load_package($pkg, 'Catmandu::Exporter')->new(@_);
}

1;

=head1 NAME

Catmandu - a data toolkit

=cut
