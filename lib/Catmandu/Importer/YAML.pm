package Catmandu::Importer::YAML;

use Catmandu::Sane;
use Moo;
use YAML::Any ();

with 'Catmandu::Importer';

my $RE_EOF = qr'^\.\.\.$';
my $RE_SEP = qr'^---';

*load_yaml = do { no strict 'refs'; \&{YAML::Any->implementation . '::Load'} };

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
                $data = load_yaml($yaml);
                $yaml = $line;
                return $data;
            }
            $yaml .= $line;
        }
        if ($yaml) {
            $data = load_yaml($yaml);
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

=head1 METHODS

=head2 new([file => $filename])

Create a new YAML importer for $filename. Use STDIN when no filename is given.

=head2 each(&callback)

The each method imports the data and executes the callback function for
each item imported. Returns the number of items imported or undef on 
failure.

=cut

1;
# package Catmandu::Importer::YAML;
# 
# use Catmandu::Sane;
# use Moo;
# use IO::YAML;
# 
# with 'Catmandu::Importer';
# 
# has yaml => (is => 'ro', lazy => 1, builder => '_build_yaml');
# 
# sub _build_yaml {
#     IO::YAML->new($_[0]->fh, auto_load => 1);
# }
# 
# sub generator {
#     my ($self) = @_;
#     sub {
#         state $yaml = $self->yaml;
#         state $data;
#         if (defined($data = <$yaml>)) {
#             return $data;
#         }
#         return;
#     };
# }
# 
# 1;
