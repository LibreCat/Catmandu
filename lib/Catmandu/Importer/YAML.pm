package Catmandu::Importer::YAML;

use Catmandu::Sane;

our $VERSION = '1.06';

use YAML::XS ();
use Moo;
use Devel::Peek;
use namespace::clean;

with 'Catmandu::Importer';

my $RE_EOF = qr'^\.\.\.$';
my $RE_SEP = qr'^---';

sub generator {
    my ($self) = @_;
    sub {
        state $fh   = $self->fh;
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

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::YAML - Package that imports YAML data

=head1 SYNOPSIS

    # From the command line

    $ catmandu convert YAML to JSON < data.yaml

    # In a Perl script

    use Catmandu;

    my $importer = Catmandu->importer('YAML',file => "/foo/bar.yaml");

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

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited. The Catmandu::Importer::YAML methods are not idempotent: YAML feeds
can only be read once.

=head1 SEE ALSO

L<Catmandu::Exporter::YAML>

=cut
