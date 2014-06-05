package Catmandu::Importer::StoreInfo;

use Catmandu::Sane;
use Moo;
use Catmandu::Importer::ModuleInfo;

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
    Catmandu::Importer::ModuleInfo->new(
        namespace => 'Catmandu::Store',
        inc       => $self->inc,
        max_depth => 1,
    );
}

=head1 NAME

Catmandu::Importer::StoreInfo - list installed Catmandu stores

=head1 OPTIONS

    inc: list of library paths (defaults to @INC)

=head1 SEE ALSO

    L<Catmandu::Importer::ModuleInfo>

=cut

1;

