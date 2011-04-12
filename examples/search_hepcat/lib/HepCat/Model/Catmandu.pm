package HepCat::Model::Catmandu;

use Dancer ':syntax';

# Minor hack to find the Catmandu lib dir within this git installation; this
# will have to be changed if you copy this example to another directory.
#
# It's handled this way because git has a tendency to duplicate the contents
# of symlinked directories when applying changes rather than maintaining the
# link as a link.  Note that if you have already installed Catmandu into your
# @INC (e.g., installing it via CPAN), the FindBin lines are superflous and
# are not required, but will not hurt anything, either.
use FindBin;
use lib "$FindBin::Bin/../../../lib";

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

