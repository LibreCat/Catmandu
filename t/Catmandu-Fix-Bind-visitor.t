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
    $pkg = 'Catmandu::Fix::Bind::visitor';
    use_ok $pkg;
}
require_ok $pkg;

my $fixes =<<EOF;
do visitor()
  add_field(hash.foo,bar)
end
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok $fixer , 'create fixer';

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing add_field';

$fixes =<<EOF;
do visitor()
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing zero fix functions';

$fixes =<<EOF;
do visitor()
  unless exists(hash.foo)
  	add_field(hash.foo,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing unless';

$fixes =<<EOF;
do visitor()
  if exists(hash.foo)
  	add_field(hash.foo2,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', foo2 => 'bar'} , 'testing if';


$fixes =<<EOF;
do visitor()
 do visitor()
  do visitor()
   add_field(hash.foo,bar)
  end
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'before/after testing';

$fixes =<<EOF;
add_field(before,ok)
do visitor()
   add_field(hash.inside,ok)
end
add_field(after,ok)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', before => 'ok', inside => 'ok', after => 'ok'} , 'before/after testing';

$fixes =<<EOF;
do visitor()
  if all_match(hash.bar,2)
    remove_field(hash.bar)
  end
end
collapse()
expand()
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix(
             {foo => [ {bar => 1}, {bar => 2} ]}
          ), {foo => [ {bar => 1} ]} , 'specific testing';

done_testing 10;