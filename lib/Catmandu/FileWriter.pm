package Catmandu::FileWriter;
# VERSION
use Moose::Role;

with qw(Catmandu::File);

sub _build_file {
    my $file = IO::Handle->new_from_fd(fileno(STDOUT), 'w');
    binmode $file, ':utf8';
    $file;
}

sub _after_file_set {
    my ($self, $file) = @_;
    binmode $file, ':utf8';
}

no Moose::Role;
1;

