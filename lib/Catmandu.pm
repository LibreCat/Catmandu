package Catmandu;

our $VERSION = '0.1';

use Catmandu::Sane;
use Catmandu::Util qw(load_package :is :check);
use Dancer qw(:syntax config);
use Exporter qw(import);

our @EXPORT_OK = qw(
    store
    importer
    exporter
);

our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $stores = {};

sub default_store { 'default' }
sub default_importer { 'JSON' }
sub default_exporter { 'JSON' }

sub store {
    my $sym = check_string(shift || default_store);

    $stores->{$sym} || do {
        if (my $cfg = check_maybe_array_ref(config->{store}{$sym})) {
            check_string(my $pkg = $cfg->[0]);
            check_hash_ref(my $args = $cfg->[1] || {});
            $stores->{$sym} = load_package($pkg, 'Catmandu::Store')->new($args);
        } else {
            load_package($sym, 'Catmandu::Store')->new(@_);
        }
    };
}

sub importer {
    my $pkg = check_string(shift);
    load_package($pkg, 'Catmandu::Importer')->new(@_);
}

sub exporter {
    my $pkg = check_string(shift);
    load_package($pkg, 'Catmandu::Exporter')->new(@_);
}

1;

=head1 NAME

Catmandu - a data toolkit

=cut
