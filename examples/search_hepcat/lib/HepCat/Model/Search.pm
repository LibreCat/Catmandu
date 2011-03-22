package HepCat::Model::Search;

use HepCat::Model::Catmandu;

sub search {
    my $class = shift;
    my $q     = shift;

    return
      HepCat::Model::Catmandu->indexer->search(
                                        $q,
                                        reify => HepCat::Model::Catmandu->store,
                                        @_
      );
}

1;

