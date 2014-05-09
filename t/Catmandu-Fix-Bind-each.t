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
    $pkg = 'Catmandu::Fix::Bind::each';
    use_ok $pkg;
}
require_ok $pkg;

my $fixes =<<EOF;
add_field(test.\$append,1)
do each(path => test)
  add_field(foo,bar)
end
remove_field(test)
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok $fixer , 'create fixer';

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing add_field';

$fixes =<<EOF;
add_field(test.\$append,1)
do each(path => test)
end
remove_field(test)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing zero fix functions';

$fixes =<<EOF;
add_field(test.\$append,1)
do each(path => test)
  unless exists(foo)
    add_field(foo,bar)
  end
end
remove_field(test)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing unless';

$fixes =<<EOF;
add_field(test.\$append,1)
do each(path => test)
  if exists(foo)
    add_field(foo2,bar)
  end
end
remove_field(test)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', foo2 => 'bar'} , 'testing if';

$fixes =<<EOF;
add_field(test.\$append,1)
do each(path => test)
  reject exists(foo)
end
remove_field(test)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok ! defined $fixer->fix({foo => 'bar'}) , 'testing reject';

$fixes =<<EOF;
add_field(test.\$append,1)
do each(path => test)
  select exists(foo)
end
remove_field(test)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing select';

$fixes =<<EOF;
add_field(test.\$append,1)
do each(path => test)
 do each(path => test)
  do each(path => test)
   add_field(foo,bar)
  end
 end
end
remove_field(test)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing nesting';

$fixes  =<<EOF;
do loop(count => 3 , index => i)
  copy_field(i,demo.\$append)
  copy_field(i,demo2.\$append)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {demo => [(qw(0 1 2))] , demo2 => [qw(0 1 2 )]} , 'testing specific loop';

$fixes  =<<EOF;
do loop(count => 3 , index => i)
  copy_field(i,demo.\$append)
  do loop(count => 3)
    copy_field(i,demo2.\$append)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {demo => [(qw(0 1 2))] , demo2 => [qw(0 0 0 1 1 1 2 2 2)]} , 'testing specific loop';

done_testing 12;