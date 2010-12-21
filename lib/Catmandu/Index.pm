package Catmandu::Index;
# ABSTRACT: Role describing a search index
# VERSION
use namespace::autoclean;
use Moose::Role;

requires 'save';
requires 'search';
requires 'delete';
requires 'commit';

has id_field => (is => 'ro', isa => 'Str', default => '_id');

1;

=head1 SYNOPSIS

    my $obj = {_id => "9BC2FC08-EE3B-11DF-BF4D-7B7478AD8B0A", title => "Island"});

    $index->save($obj);

    $index->delete($obj);
    $index->delete("9BC2FC08-EE3B-11DF-BF4D-7B7478AD8B0A");

    my ($hits, $total_hits) = $index->search("query");

    # return objects with matching _id from $store instead of the stored fields
    my $objects = $index->search("query", reify => $store);

    $index->search("query", start => 50, limit => 10);

    $index->commit

=head1 METHODS

=head2 $c->save($obj)

Inserts or updates C<$obj> in the index. Returns the saved object.

=head2 $c->delete($obj|$id)

Delete C<$obj> or object with _id C<$id> from the index.

=head2 $c->search($query, %opts)

Takes the following optional arguments:

reify: A store to load objects with matching _id from instead of
returning the stored fields.

start: Number of results to skip. Default is 0.

limit: Maximum number of results to return. Default is 50.

Calls commit before searching so that results are up to date.

Returns an arrayref of hits/objects and the total number of hits.

=head2 $c->commit

Commits pending changes to the index.

=head1 SEE ALSO

L<Catmandu::Index::Simple>, an included Index implementation that uses L<KinoSearch> as indexing layer.

