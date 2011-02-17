package Catmandu::FileReader;
# VERSION
use Moose::Role;

with qw(Catmandu::File);

sub _build_file {
    IO::Handle->new_from_fd(fileno(STDIN), 'r');
}

sub _after_file_set {
    my ($self, $file) = @_;

    if ($file->can('seek')) {
        $file->seek(0, 0); #rewind
    }
}

no Moose::Role;

1;

