package Catmandu;
use Catmandu::Sane;
use Catmandu::Util qw(load_package);
use Dancer qw(:syntax setting);
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

    state $memo = {};
    if (my $val = $memo->{$pkg}) {
        return $val;
    }

    if ($pkg =~ /^[a-z]/) {
        my $key = $pkg;
        my $cfg = setting('store')->{$key};
        ($pkg, @args) = @$cfg;
        $memo->{$key} = load_package($pkg, 'Catmandu::Store')->new(@args);
    } else {
        load_package($pkg, 'Catmandu::Store')->new(@args);
    }
}

sub new_index {
    my ($pkg, @args) = @_;
    $pkg ||= 'default';

    state $memo = {};
    if (my $val = $memo->{$pkg}) {
        return $val;
    }

    if ($pkg =~ /^[a-z]/) {
        my $key = $pkg;
        my $cfg = setting('index')->{$key};
        ($pkg, @args) = @$cfg;
        $memo->{$key} = load_package($pkg, 'Catmandu::Index')->new(@args);
    } else {
        load_package($pkg, 'Catmandu::Index')->new(@args);
    }
}

sub new_filestore {
    my ($pkg, @args) = @_;
    $pkg ||= 'default';

    state $memo = {};
    if (my $val = $memo->{$pkg}) {
        return $val;
    }

    if ($pkg =~ /^[a-z]/) {
        my $key = $pkg;
        my $cfg = setting('filestore')->{$key};
        ($pkg, @args) = @$cfg;
        $memo->{$key} = load_package($pkg, 'Catmandu::Filestore')->new(@args);
    } else {
        load_package($pkg, 'Catmandu::Filestore')->new(@args);
    }
}

sub new_importer {
    my ($pkg, @args) = @_;
    load_package($pkg, 'Catmandu::Importer')->new(@args);
}

sub new_exporter {
    my ($pkg, @args) = @_;
    load_package($pkg, 'Catmandu::Exporter')->new(@args);
}

*get_store = \&new_store;
*get_index = \&new_index;
*get_filestore = \&new_filestore;

1;

=head1 NAME

Catmandu - a data toolkit

=cut
