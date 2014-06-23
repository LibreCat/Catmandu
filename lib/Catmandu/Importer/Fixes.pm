package Catmandu::Importer::Fixes;

use Catmandu::Sane;
use Moo;
use Catmandu::Importer::Modules;

has inc => (
    is      => 'ro',
    default => sub { [@INC] },
);

has _module_info => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_module_info',
    handles => 'Catmandu::Importer',
);

sub _build_module_info {
    my ($self) = @_;
    Catmandu::Importer::Modules->new(
        namespace => 'Catmandu::Fix',
        inc       => $self->inc,
        pattern   => qr/:[a-z][^:]*$/,
    );
}

=head1 NAME

Catmandu::Importer::Fixes - list installed Catmandu fixes

=head1 OPTIONS

    inc: list of library paths (defaults to @INC)

=head1 SEE ALSO

L<Catmandu::Importer::Modules>

=cut

1;
