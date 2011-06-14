package Catmandu::Importer::YAML;
use Catmandu::Sane;
use Catmandu::Util qw(io);
use Catmandu::Object file => { default => sub { *STDIN } };
use IO::YAML;

sub each {
    my ($self, $sub) = @_;

    my $file = IO::YAML->new(io($self->file, 'r'), auto_load => 1);
    my $n = 0;

    while (defined(my $obj = <$file>)) {
        $sub->($obj);
        $n++;
    }

    $n;
}

1;
