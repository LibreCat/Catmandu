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
