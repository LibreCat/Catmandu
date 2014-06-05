package Catmandu::Importer::ModuleInfo;

use namespace::clean;
use Catmandu::Sane;
use Module::Info;
use File::Spec;
use File::Find::Rule;
use Moo;

with 'Catmandu::Importer';

has inc => (
    is      => 'ro',
    lazy    => 1,
    default => sub { [@INC] },
);

has namespace => (
    is      => 'ro',
    default => sub { "" },
);

has max_depth => (
    is        => 'ro',
    predicate => 1,
);

sub generator {
    my ($self) = @_;

    sub {
        state $dirs = do {
            my @ns  = grep length, split(/::/, $self->namespace);
            my $inc = $self->inc;
            [ map { File::Spec->catdir($_, @ns) } @$inc ];
        };

        state $dir = shift(@$dirs) // return;

        state $rule = do {
            my $r = File::Find::Rule->new->file->name('*.pm');
            $r->maxdepth($self->max_depth) if $self->has_max_depth;
            $r->start($dir);
        };

        while (1) {
            if (defined(my $file = $rule->match)) {
                my $info = Module::Info->new_from_file($file);
                my $name = join('::', File::Spec->splitdir(File::Spec->abs2rel($file, $dir)));
                $name =~ s/\.pm$//;
                $name = join('::', $self->namespace, $name) if $self->namespace;

                my $data = {
                    file => $file,
                    name => $name,
                };
                $data->{version} = $info->version if defined $info->version;
                return $data;
            } else {
                $dir = shift(@$dirs) // return;
                $rule->start($dir);
            }
        }
    };
}

=head1 NAME

    Catmandu::Importer::ModuleInfo - list system available packages in a given namespace

=head1 OPTIONS

    namespace:      namespace for the packages to list
    inc:            override list of lookup directories (defaults to @INC)
    max_depth:      maximum depth to search for. Depth means the number of words in the package name
                    e.g.  Catmandu::Fix has a depth of 2
                          Catmandu::Importer::JSON has a depth of 3

=head1 SEE ALSO

    L<Catmandu::Importer>

=cut

1;
