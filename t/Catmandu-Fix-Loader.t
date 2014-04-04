
package FooBar;

use Moo;

sub fix {}

package main;
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Loader';
    use_ok $pkg;
}
require_ok $pkg;

is_deeply Catmandu::Fix::Loader::load_fixes() , [] , 'empty fixes';

my $fixer = Catmandu::Fix::Loader::load_fixes(['nothing();']);
ok $fixer , qq|nothing() string|;
isa_ok $fixer->[0] , qq|Catmandu::Fix::nothing|;

my $fixer2 = Catmandu::Fix::Loader::load_fixes(['t/nothing.fix']);
ok $fixer2 , qq|nothing() file|;
isa_ok $fixer2->[0] , qq|Catmandu::Fix::nothing|;

my $fixer3 = Catmandu::Fix::Loader::load_fixes([FooBar->new]);
ok $fixer3 , qq|FooBar fixer|;
isa_ok $fixer3->[0] , qq|FooBar|;

done_testing 9;