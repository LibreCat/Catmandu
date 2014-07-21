package Catmandu::Importer::YAML;

use namespace::clean;
use Catmandu::Sane;
use YAML::XS ();
use Moo;
use Devel::Peek;

with 'Catmandu::Importer';

my $RE_EOF = qr'^\.\.\.$';
my $RE_SEP = qr'^---';

sub generator {
    my ($self) = @_;
    sub {
        state $fh = $self->fh;
        state $yaml = "";
        state $data;
        state $line;
        while (defined($line = <$fh>)) {
            if ($line =~ $RE_EOF) {
                last;
            }
            if ($line =~ $RE_SEP && $yaml) {
                utf8::encode($yaml);
                $data = YAML::XS::Load($yaml);
                $yaml = $line;
                return $data;
            }
            $yaml .= $line;
        }
        if ($yaml) { 
            utf8::encode($yaml);
            $data = YAML::XS::Load($yaml);
            $yaml = "";
            return $data;
        }
        return;
    };
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

    The YAML input file needs to be separated into records:

    ---
    - recordno: 1
    - name: Alpha
    ---
    - recordno: 2
    - name: Beta
    ...

    where '---' is the record separator and '...' the EOF indicator.

=head1 METHODS

=head2 new(file => $filename, fh => $fh , fix => [...])

Create a new YAML importer for $filename. Use STDIN when no filename is given.

The constructor inherits the fix parameter from L<Catmandu::Fixable>. When given,
then any fix or fix script will be applied to imported items.

=head2 count

=head2 each(&callback)

=head2 ...

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited. The Catmandu::Importer::YAML methods are not idempotent: YAML feeds
can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
