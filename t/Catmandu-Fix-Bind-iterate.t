#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix;
use Catmandu::Importer::Mock;
use Catmandu::Util qw(:is);

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Bind::iterate';
    use_ok $pkg;
}
require_ok $pkg;

my $fixes = <<EOF;
do iterate(start:0,end:9)
  add_field(foo,bar)
end
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok $fixer , 'create fixer';

is_deeply $fixer->fix({}), {foo => 'bar'}, 'testing add_field';

$fixes = <<EOF;
do iterate()
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'},
    'testing zero fix functions';

$fixes = <<EOF;
do iterate(start:0,end:9)
  unless exists(foo)
  	add_field(foo,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {foo => 'bar'}, 'testing unless';

$fixes = <<EOF;
do iterate(start:0,end:9)
  if exists(foo)
  	add_field(foo2,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', foo2 => 'bar'},
    'testing if';

$fixes = <<EOF;
do iterate(start:0,end:9)
  reject exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok !defined $fixer->fix({foo => 'bar'}), 'testing reject';

$fixes = <<EOF;
do iterate(start:0,end:9)
  select exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'testing select';

$fixes = <<EOF;
do iterate(start:0,end:3)
 do iterate(start:0,end:3)
  do iterate(start:0,end:3)
   add_field(foo,bar)
  end
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'before/after testing';

$fixes = <<EOF;
add_field(before,ok)
do iterate(start:0,end:9)
   add_field(inside,ok)
end
add_field(after,ok)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}),
    {foo => 'bar', before => 'ok', inside => 'ok', after => 'ok'},
    'before/after testing';

$fixes = <<EOF;
do iterate(start:0,end:9,var:i)
  copy_field(i,test.\$append)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {test => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]},
    'specific testing';

done_testing 12;
