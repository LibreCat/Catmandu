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

=head1 NAME

Catmandu::Importer::YAML - Package that imports YAML data

=head1 SYNOPSIS

    use Catmandu::Importer::YAML;

    my $importer = Catmandu::Importer::YAML->new(file => "/foo/bar.yaml");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new([file => $filename])

Create a new YAML importer for $filename. Use STDIN when no filename is given.

=head2 each(&callback)

The each method imports the data and executes the callback function for
each item imported. Returns the number of items imported or undef on 
failure.

=cut

1;
