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
    $pkg = 'Catmandu::Fix::Bind::with';
    use_ok $pkg;
}
require_ok $pkg;

my $fixes =<<EOF;
do with()
  add_field(foo,bar)
end
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok $fixer , 'create fixer';

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing add_field';

$fixes =<<EOF;
do with()
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing zero fix functions';

$fixes =<<EOF;
do with()
  unless exists(foo)
  	add_field(foo,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing unless';

$fixes =<<EOF;
do with()
  if exists(foo)
  	add_field(foo2,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', foo2 => 'bar'} , 'testing if';

$fixes =<<EOF;
do with()
  reject exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}) , {}, 'testing reject';

$fixes =<<EOF;
do with()
  select exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing select';

$fixes =<<EOF;
do with()
 do with()
  do with()
   add_field(foo,bar)
  end
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'before/after testing';

$fixes =<<EOF;
add_field(before,ok)
do with()
   add_field(inside,ok)
end
add_field(after,ok)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', before => 'ok', inside => 'ok', after => 'ok'} , 'before/after testing';

$fixes =<<EOF;
do with(path => foo)
  if all_match(bar,2)
    reject()
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix(
             {foo => [ {bar => 1}, {bar => 2} ]}
          ), {foo => [ {bar => 1} ]} , 'specific testing';

done_testing 12;