package HepCat::Model::Catmandu;

use Dancer ':syntax';

use Catmandu;
use Catmandu::Util;

my $indexer;
sub indexer {
    unless (defined $indexer) {
        my $class = Catmandu::Util::load_class(config->{catmandu_indexer});
        my $args = config->{catmandu_indexer_args};
        $indexer = $class->new($args);
    }
    return $indexer;
}

my $store;
sub store {
    unless (defined $store) {
        my $class = Catmandu::Util::load_class(config->{catmandu_store});
        my $args = config->{catmandu_store_args};
        $store = $class->new($args);
    }
    return $store;
}

1;

