package Catmandu::Importer::Modules;

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
    coerce  => sub {
        my $inc = $_[0];
        return $inc if ref $inc eq 'ARRAY';
        return [split ',', $inc];
    },
);

has namespace => (
    is      => 'ro',
    default => sub { "" },
);

has max_depth => (
    is        => 'ro',
    predicate => 1,
);

has pattern => (
    is => 'ro',
);

sub generator {
    my ($self) = @_;

    sub {
        state $pattern = $self->pattern;

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
                my $name = join('::', File::Spec->splitdir(File::Spec->abs2rel($file, $dir)));
                $name =~ s/\.pm$//;
                $name = join('::', $self->namespace, $name) if $self->namespace;

                next if defined $pattern && $name !~ $pattern;

                my $info = Module::Info->new_from_file($file);

                my $data = {
                    file => File::Spec->rel2abs($file),
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

Catmandu::Importer::Modules - list installed perl modules in a given namespace

=head1 OPTIONS

=over

=item namespace

namespace for the packages to list

=item inc

list of library paths (defaults to C<@INC>)

=item max_depth

maximum depth to recurse into the namespace e.g. if the namespace is
Catmandu::Fix then Catmandu::Fix::add_field has a depth of 1 and
Catmandu::Fix::Condition::exists a depth of 2

=item pattern

filter modules by the given regex pattern

=back

=cut

1;
