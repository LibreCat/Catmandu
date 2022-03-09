use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::Count';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
    {'a' => 'moose',  b => '1'},
    {'a' => 'pony',   b => '2'},
    {'a' => 'shrimp', b => '3'}
];
my $out = "";

my $exporter = $pkg->new(file => \$out);
isa_ok $exporter, $pkg;

$exporter->add($_) for @$data;
$exporter->commit;

is $out,             "3\n", "Null is empty ok";
is $exporter->count, 3,     "Count ok";

{

    package T::Countable;

    use Catmandu::Sane;
    use Moo;

    with 'Catmandu::Iterable';

    has count_used => (is => 'rwp', default => sub {0});

    sub generator {
        my $i = 0;
        sub {
            return if $i;
            return {i => $i++};
        }
    }

    sub count {
        $_[0]->_set_count_used(1);
        1;
    }
};

$exporter = $pkg->new;
$exporter->add_many(my $it = T::Countable->new);
$exporter->commit;
ok $it->count_used, 'use optimized count method when available';

done_testing;
