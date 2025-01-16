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
    $pkg = 'Catmandu::Fix::Bind::timeout';
    use_ok $pkg;
}
require_ok $pkg;

my $fixes = <<EOF;
do timeout(time => 2 , units => 'seconds')
  add_field(foo,bar)
end
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok $fixer, 'create fixer';

is_deeply $fixer->fix({}), {foo => 'bar'}, 'testing add_field';

$fixes = <<EOF;
do timeout(time => 2 , units => 'seconds')
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'},
    'testing zero fix functions';

$fixes = <<EOF;
do timeout(time => 2 , units => 'seconds')
  unless exists(foo)
    add_field(foo,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {foo => 'bar'}, 'testing unless';

$fixes = <<EOF;
do timeout(time => 2 , units => 'seconds')
  if exists(foo)
    add_field(foo2,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', foo2 => 'bar'},
    'testing if';

$fixes = <<EOF;
do timeout(time => 2 , units => 'seconds')
  reject exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is $fixer->fix({foo => 'bar'}), undef, 'testing reject';

$fixes = <<EOF;
do timeout(time => 2 , units => 'seconds')
  select exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'testing select';

$fixes = <<EOF;
do timeout(time => 2 , units => 'seconds')
 do timeout(time => 2 , units => 'seconds')
  do timeout(time => 2 , units => 'seconds')
   add_field(foo,bar)
  end
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'before/after testing';

$fixes = <<EOF;
add_field(before,ok)
do timeout(time => 2 , units => 'seconds')
   add_field(inside,ok)
end
add_field(after,ok)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}),
    {foo => 'bar', before => 'ok', inside => 'ok', after => 'ok'},
    'before/after testing';

$fixes = <<EOF;
do timeout(time => 0.1 , units => 'seconds')
   add_field(test,ok)
   sleep(0.5,seconds)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'specific testing';

$fixes = <<EOF;
do timeout(time => 0.1 , units => 'seconds')
   sleep(0.5,seconds)
   add_field(test,ok)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'specific testing';

$fixes = <<EOF;
do timeout(time => 0.1 , units => 'seconds')
   sleep(0.5,seconds)
   reject()
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'specific testing';

done_testing;
