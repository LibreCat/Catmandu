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
    $pkg = 'Catmandu::Fix::Bind::state';
    use_ok $pkg;
}
require_ok $pkg;

my $fixes =<<EOF;
do state(field => 'global')
  add_field(foo,bar)
end
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok $fixer , 'create fixer';

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing add_field';

$fixes =<<EOF;
do state(field => 'global')
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing zero fix functions';

$fixes =<<EOF;
do state(field => 'global')
  unless exists(foo)
  	add_field(foo,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing unless';

$fixes =<<EOF;
do state(field => 'global')
  if exists(foo)
  	add_field(foo2,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', foo2 => 'bar'} , 'testing if';

$fixes =<<EOF;
do state(field => 'global')
  reject exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is $fixer->fix({foo => 'bar'}) , undef, 'testing reject';

$fixes =<<EOF;
do state(field => 'global')
  select exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing select';

$fixes =<<EOF;
do state(field => 'global')
 do state(field => 'global')
  do state(field => 'global')
   add_field(foo,bar)
  end
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'before/after testing';

$fixes =<<EOF;
add_field(before,ok)
do state(field => 'global')
   add_field(inside,ok)
end
add_field(after,ok)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', before => 'ok', inside => 'ok', after => 'ok'} , 'before/after testing';

$fixes =<<EOF;
do state(field => 'global')
   add_field(global.test.\$append,ok)
   copy_field(global.test,result)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix(
             [{},{}]
          ), [{result => ['ok']}, {result => ['ok','ok']}], 'specific testing';

done_testing 12;