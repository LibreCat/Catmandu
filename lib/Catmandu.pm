package Catmandu;
use Catmandu::Sane;
use Catmandu::Util qw(load_package);
use Dancer qw(:syntax config);
use Exporter qw(import);

our $VERSION = '0.1';

our @EXPORT_OK = qw(
    new_store
    new_index
    new_filestore
    new_importer
    new_exporter
    get_store
    get_index
    get_filestore
);

sub new_store {
    my ($pkg, @args) = @_;
    $pkg ||= 'default';
    if ($pkg !~ /^[A-Z]/) {
        my $cfg = config->{store}{$pkg};
        ($pkg, @args) = @$cfg;
    }
    load_package($pkg, 'Catmandu::Store')->new(@args);
}

sub new_index {
    my ($pkg, @args) = @_;
    $pkg ||= 'default';
    if ($pkg !~ /^[A-Z]/) {
        my $cfg = config->{index}{$pkg};
        ($pkg, @args) = @$cfg;
    }
    load_package($pkg, 'Catmandu::Index')->new(@args);
}

sub new_filestore {
    my ($pkg, @args) = @_;
    $pkg ||= 'default';
    if ($pkg !~ /^[A-Z]/) {
        my $cfg = config->{filestore}{$pkg};
        ($pkg, @args) = @$cfg;
    }
    load_package($pkg, 'Catmandu::Filestore')->new(@args);
}

sub new_importer {
    my ($pkg, @args) = @_;
    load_package($pkg, 'Catmandu::Importer')->new(@args);
}

sub new_exporter {
    my ($pkg, @args) = @_;
    load_package($pkg, 'Catmandu::Exporter')->new(@args);
}

sub get_store {
    my $key = $_[0] || 'default';
    state $memo = {};
    $memo->{$key} ||= new_store($key);
}

sub get_index {
    my $key = $_[0] || 'default';
    state $memo = {};
    $memo->{$key} ||= new_index($key);
}

sub get_filestore {
    my $key = $_[0] || 'default';
    state $memo = {};
    $memo->{$key} ||= new_filestore($key);
}

1;
