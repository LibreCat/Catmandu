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
    export
    export_to_string
);

our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $stores = {};

sub default_store { 'default' }

sub store {
    my $sym = check_string(shift || default_store);

    $stores->{$sym} || do {
        if (my $cfg = config->{store}{$sym}) {
            check_hash_ref($cfg);
            check_string(my $pkg = $cfg->{package});
            check_hash_ref(my $opts = $cfg->{options} || {});
            $opts = is_hash_ref($_[0])
                ? {%$opts, %{$_[0]}}
                : {%$opts, @_};
            $stores->{$sym} = load_package($pkg, 'Catmandu::Store')->new($opts);
        } else {
            load_package($sym, 'Catmandu::Store')->new(@_);
        }
    };
}

sub importer {
    my $sym = check_string(shift);
    if (my $cfg = config->{importer}{$sym}) {
        check_hash_ref($cfg);
        check_string(my $pkg = $cfg->{package});
        check_hash_ref(my $opts = $cfg->{options} || {});
        $opts = is_hash_ref($_[0])
            ? {%$opts, %{$_[0]}}
            : {%$opts, @_};
        load_package($pkg, 'Catmandu::Importer')->new($opts);
    } else {
        load_package($sym, 'Catmandu::Importer')->new(@_);
    }
}

sub exporter {
    my $sym = check_string(shift);
    if (my $cfg = config->{exporter}{$sym}) {
        check_hash_ref($cfg);
        check_string(my $pkg = $cfg->{package});
        check_hash_ref(my $opts = $cfg->{options} || {});
        $opts = is_hash_ref($_[0])
            ? {%$opts, %{$_[0]}}
            : {%$opts, @_};
        load_package($pkg, 'Catmandu::Exporter')->new($opts);
    } else {
        load_package($sym, 'Catmandu::Exporter')->new(@_);
    }
}

sub export {
    my $data = shift;
    my $exporter = exporter(@_);
    is_hash_ref($data)
        ? $exporter->add($data)
        : $exporter->add_many($data);
    $exporter->commit;
    return;
}

sub export_to_string {
    my $data = shift;
    my $sym  = shift;
    my %opts = is_hash_ref($_[0]) ? %{$_[0]} : @_;
    my $str  = "";
    my $exporter = exporter($sym, %opts, file => \$str);
    is_hash_ref($data)
        ? $exporter->add($data)
        : $exporter->add_many($data);
    $exporter->commit;
    $str;
}

1;

=head1 NAME

Catmandu - a data toolkit

=cut
