package Catmandu::Store::Memory::Bag;

our $VERSION = '0.01';

use Catmandu::Sane;
use Moo;
use Catmandu::Util;
use Catmandu::FileStore::MimeType;
use namespace::clean;

with 'Catmandu::FileStore::Bag';

has _mimeType => (is => 'lazy');

sub _build__mimeType {
    Catmandu::FileStore::MimeType->new;
}

sub generator {
    my ($self) = @_;

    my $name  = $self->name;
    my $files = $self->store->_files->{$name} // {};

    sub {
        state $ids = [ keys %$files ];

        my $id = pop @$ids;

        return undef unless $id;

        return $self->get($id);
    };
}

sub exists {
    my ($self, $id) = @_;

    my $name  = $self->name;
    my $files = $self->store->_files->{$name} // {};

    exists $files->{$id};
}

sub get {
    my ($self, $id) = @_;

    my $name  = $self->name;
    my $files = $self->store->_files->{$name} // {};

    $files->{$id};
}

sub add {
    my ($self, $data) = @_;

    my $id    = $data->{_id};
    my $io    = $data->{_stream};

    delete $data->{_stream};

    my $name  = $self->name;

    my $str = Catmandu::Util::read_io($io);

    $self->store->_files->{$name}->{$id} = {
        _id      => $id ,
        size     => length $str ,
        md5      => '' ,
        content_type => $self->_mimeType->content_type($id) ,
        created  => time ,
        modified => time ,
        _stream  => sub {
            my $io = $_[0];

            Catmandu::Error->throw("no io defined or not writable") unless defined($io);

            $io->write($str);
        } ,
        %$data
    };

    1;
}

sub delete {
    my ($self, $id) = @_;

    my $name  = $self->name;
    my $files = $self->store->_files->{$name} // {};

    delete $files->{$id};
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

1;
