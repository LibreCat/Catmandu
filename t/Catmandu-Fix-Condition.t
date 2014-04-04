use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Condition';
    use_ok $pkg;
}
require_ok $pkg;

#
# Catmandu::Fix::Condition: need some rework to fic if_otherwise bugs..
#

done_testing 2;
