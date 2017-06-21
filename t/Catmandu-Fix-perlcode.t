use strict;
use warnings;
use Test::More;
use Catmandu::Fix;
use Catmandu::Fix::perlcode;

foreach my $i (1 .. 2) {    # also tests caching
    my $fixer = Catmandu::Fix->new(fixes => ['perlcode(./t/script.pl)']);
    my $data = {};
    $fixer->fix($data);
    is_deeply $data, {answer => 42}, 'perlcode fix';
}

{
    my $fixer = Catmandu::Fix->new(fixes => ['perlcode(./t/script.pl)']);
    is_deeply $fixer->fix([map {+{answer => $_}} 1 .. 3]),
        [{answer => 1}, {answer => 3}], 'perlcode fix with reject';
}

done_testing;
