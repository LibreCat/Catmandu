package Catmandu::Store::Simple::Bag;

our $VERSION = '1.0507';

use Catmandu::Sane;
use Moo;
use Carp;
use IO::File;
use Path::Tiny;
use File::Spec;
use File::Copy;
use Catmandu::Util;
use URI::Escape;
use Catmandu::FileStore::MimeType;
use namespace::clean;
use utf8;

with 'Catmandu::FileStore::Bag';

has _path     => (is => 'lazy');
has _mimeType => (is => 'lazy');

sub _build__path {
    my $self = shift;
    $self->store->path_string($self->name);
}

sub _build__mimeType {
    Catmandu::FileStore::MimeType->new;
}

sub generator {
    my ($self) = @_;
    my $path = $self->_path;

    sub {
        state $children = [ path($path)->children ];

        my $child = shift @$children;

        return undef unless $child;

        my ($volume,$directories,$file) = File::Spec->splitpath($child);

        next if index($file, ".") == 0;

        my $unpacked_key = $self->unpack_key($file);

        return $self->get($unpacked_key);
    };
}

sub exists {
    my ($self, $id) = @_;
    my $path = $self->_path;

    my $packed_key = $self->pack_key($id);

    my $file = File::Spec->catfile($path,$packed_key);

    -f $file;
}

sub get {
    my ($self, $id) = @_;
    my $path = $self->_path;

    my $packed_key = $self->pack_key($id);

    my $file = File::Spec->catfile($path,$packed_key);

    return undef unless -f $file;

    my $data = IO::File->new($file, "r");

    my $stat = [$data->stat];

    my $size     = $stat->[7];
    my $modified = $stat->[9];
    my $created  = $stat->[10];    # no real creation time exists on Unix

    my $content_type = $self->_mimeType->content_type($id);

    return {
        _id          => $id,
        size         => $size,
        md5          => '',
        content_type => $content_type,
        created      => $created,
        modified     => $modified,
        _stream      => sub {
            my $out = $_[0];
            my $bytes = 0;

            Catmandu::Error->throw("no io defined or not writable") unless defined($out);

            while (!$data->eof) {
                my $buffer;
                $data->read($buffer, 1024);
                $bytes += $out->write($buffer);
            }

            $out->close();
            $data->close();

            $bytes;
        }
    };
}

sub add {
    my ($self, $data) = @_;
    my $path = $self->_path;

    my $id = $data->{_id};
    my $io = $data->{_stream};

    return $self->get($id) unless $io;

    my $packed_key = $self->pack_key($id);

    my $file = File::Spec->catfile($path,$packed_key);

    if (Catmandu::Util::is_invocant($io)) {
        return copy($io, $file);
    }
    else {
        return Catmandu::Util::write_file($file, $io);
    }

    return $self->get($id);
}

sub delete {
    my ($self, $id) = @_;
    my $path = $self->_path;

    my $packed_key = $self->pack_key($id);

    my $file = File::Spec->catfile($path,$packed_key);

    return undef unless -f $file;

    unlink $file;
}

sub delete_all {
    my ($self) = @_;

    $self->each(sub {
        my $key = shift->{_id};
        $self->delete($key);
    });

    1;
}

sub commit {
    return 1;
}

sub pack_key {
    my $self = shift;
    my $key  = shift;
    utf8::encode($key);
    uri_escape($key);
}

sub unpack_key {
    my $self = shift;
    my $key  = shift;
    my $str  = uri_unescape($key);
    utf8::decode($str);
    $str;
}

1;
