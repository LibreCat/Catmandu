use strict;
use warnings;
use Catmandu::Fix;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Condition';
    use_ok $pkg;
}
require_ok $pkg;

my $fixer;

my $fixes_old =<<EOF;
if_all_match('oogly.*', 'doogly');
   upcase('foo'); 
end();
EOF

my $fixes_new =<<EOF;
if all_match('oogly.*', 'doogly')
   upcase('foo')
end
EOF

ok $fixer = Catmandu::Fix->new(fixes => [$fixes_old]);
ok $fixer = Catmandu::Fix->new(fixes => [$fixes_new]);

done_testing 4;
