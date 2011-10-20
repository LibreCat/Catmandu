package Catmandu::Exporter::YAML;
use Catmandu::Sane;
use Catmandu::Util qw(io quacks);
use IO::YAML;
use Catmandu::Object file => { default => sub { *STDOUT } };

sub add {
    my ($self, $obj) = @_;

    my $file = IO::YAML->new(io($self->file, 'w'), auto_load => 1);

    if (quacks $obj, 'each') {
        return $obj->each(sub {
            print $file $_[0];
        });
    }

    print $file $obj;
    1;
}

1;
