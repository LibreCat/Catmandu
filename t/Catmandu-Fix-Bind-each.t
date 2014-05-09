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
    $pkg = 'Catmandu::Fix::Bind::loop';
    use_ok $pkg;
}
require_ok $pkg;

my $fixes =<<EOF;
do loop(count => 1)
  add_field(foo,bar)
end
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok $fixer , 'create fixer';

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing add_field';

$fixes =<<EOF;
do loop(count => 1)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing zero fix functions';

$fixes =<<EOF;
do loop(count => 1)
  unless exists(foo)
  	add_field(foo,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing unless';

$fixes =<<EOF;
do loop(count => 1)
  if exists(foo)
  	add_field(foo2,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', foo2 => 'bar'} , 'testing if';

$fixes =<<EOF;
do loop(count => 1)
  reject exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), undef , 'testing reject';

$fixes =<<EOF;
do loop(count => 1)
  select exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing select';

$fixes =<<EOF;
do loop(count => 1)
 do loop(count => 1)
  do loop(count => 1)
   add_field(foo,bar)
  end
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing nesting';

$fixes =<<EOF;
add_field(demo.\$append,foo)
add_field(demo.\$append,bar)
do each(path => demo, index => i)
  do each(path => demo)
    copy_field(i,demo2.\$append)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), { demo => [qw(foo bar)] , demo2 => [qw(foo foo bar bar)] } , 'testing each specifics';

done_testing 11;
