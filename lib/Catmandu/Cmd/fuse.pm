package Catmandu::Cmd::fuse;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu qw(:all);
use Dancer qw(:syntax config);
use POSIX qw(ENOENT EISDIR);
use JSON ();

sub command_opt_spec {
    (
        [ "mountpoint=s", "", { required => 1 } ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;
    load_package('Fuse');
    Fuse::main(
        mountpoint => $opts->mountpoint,
        getattr    => __PACKAGE__.'::fs_getattr',
        getdir     => __PACKAGE__.'::fs_getdir',
        statfs     => __PACKAGE__.'::fs_statfs',
        open       => __PACKAGE__.'::fs_open',
        read       => __PACKAGE__.'::fs_read',
    );
}

my $time = time - 1000;
my $stores = config->{store} || {};

sub _normalize_path {
    my ($path) = @_;
    $path =~ s!^/+!!;
    $path =~ s!/+$!!;
    $path = '.' unless length $path;
    $path;
}

sub _getattr {
    my ($type, $mode, $size) = @_;
    $size //= 0;
    my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = (0, 0, 0, 1, 0, 0, 1, 1024);
    my ($atime, $ctime, $mtime) = ($time, $time, $time);
    my ($modes) = ($type<<9) + $mode;
    return $dev, $ino, $modes, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks;
}

sub fs_getattr {
    my ($file) = @_;
    $file = _normalize_path($file);
    if ($file eq '.') {
        return _getattr(0040, 0755);
    }
    my @path = split '/', $file;
    if (@path == 1) {
        return _getattr(0040, 0755) if $stores->{$file};
        return -ENOENT();
    }
    if (@path == 2) {
        $stores->{$path[0]} || return -ENOENT();
        my $store = store($path[0]);
        $store->bags->{$path[1]} || return -ENOENT();
        return _getattr(0040, 0755);
    }
    if (@path == 3) {
        $stores->{$path[0]} || return -ENOENT();
        my $store = store($path[0]);
        $store->bags->{$path[1]} || return -ENOENT();
        my $bag   = $store->bag($path[1]);
        my $data  = $bag->get($path[2]) || return -ENOENT();
        my $json  = JSON::encode_json($data);
        return _getattr(0100, 0644, length $json);
    }
    return -ENOENT();
}

sub fs_getdir {
    my ($dir) = @_;
    $dir = _normalize_path($dir);
    if ($dir eq '.' ) {
        return ('.', sort keys %$stores), 0;
    }
    my @path = split '/', $dir;
    if (@path == 1) {
        my $store = store($path[0]);
        my $bags  = $store->bags;
        return ('.', sort keys %$bags), 0;
    }
    return ('.'), 0;
}

sub fs_open {
    my ($file, $flags, $file_info) = @_;
    $file = _normalize_path($file);
    my @path = split '/', $file;
    if (@path == 1) {
        return -EISDIR() if $stores->{$file};
        return -ENOENT();
    }
    if (@path == 2) {
        $stores->{$path[0]} || return -ENOENT();
        my $store = store($path[0]);
        $store->bags->{$path[1]} || return -ENOENT();
        return -EISDIR();
    }
    if (@path == 3) {
        $stores->{$path[0]} || return -ENOENT();
        my $store = store($path[0]);
        $store->bags->{$path[1]} || return -ENOENT();
        my $bag = $store->bag($path[1]);
        $bag->get($path[2]) || return -ENOENT();
        return 0, [ rand ];
    }
    return -ENOENT();
}

sub fs_read {
    my ($file, $buf, $offset, $fh) = @_;
    $file = _normalize_path($file);
    my @path = split '/', $file;
    if (@path == 1) {
        return -EISDIR() if $stores->{$file};
        return -ENOENT();
    }
    if (@path == 2) {
        $stores->{$path[0]} || return -ENOENT();
        my $store = store($path[0]);
        $store->bags->{$path[1]} || return -ENOENT();
        return -EISDIR();
    }
    if (@path == 3) {
        $stores->{$path[0]} || return -ENOENT();
        my $store = store($path[0]);
        $store->bags->{$path[1]} || return -ENOENT();
        my $bag = $store->bag($path[1]);
        my $data = $bag->get($path[2]) || return -ENOENT();
        my $json = JSON::encode_json($data);
        return -EINVAL() if $offset > length($json);
        return 0 if $offset == length($json);
        return substr($json, $offset, $buf);
    }
    return -ENOENT();
}

sub fs_statfs {
    return 255, 1, 1, 1, 1, 2;
}

1;

=head1 NAME

Catmandu::Cmd::fuse - expose stores as a FUSE filesystem

