package Catmandu::Import::YAML;
use IO::YAML;
use Catmandu::Util;
use Catmandu::Class qw(file);

sub build {
    my ($self, $args) = @_;
    $self->{file} = $args->{file} || *STDIN;
}

sub default_attribute {
    'file';
}

sub each {
    my ($self, $sub) = @_;

    my $file = IO::YAML->new(Catmandu::Util::io($self->file, 'r'), auto_load => 1);
    my $n = 0;

    while (defined(my $obj = <$file>)) {
        $sub->($obj);
        $n++;
    }

    $n;
}

1;
