package Catmandu::MultiIterator;

use Catmandu::Sane;
use Moo;
use namespace::clean;

with 'Catmandu::MultiIterable';

sub BUILDARGS {
    my ($class, @iterators) = @_;
    return {iterators => [ @importers ]};
}
__END__

=head1 NAME

Catmandu::MultiIterator - chain multiple iterators together

=head1 SYNOPSIS

    my $it = Catmandu::MultiIterator->new(
        Catmandu::Importer::Mock->new,
        Catmandu::Importer::Mock->new,
    );

    # return all the items of each importer in turn
    $it->each(sub {
        # ...
    });

=head1 METHODS

All L<Catmandu::Iterable> methods are available.

=cut

1;

