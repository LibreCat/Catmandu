#!/usr/bin/env perl
package Catmandu::Fix::throw_error;

use Moo;

sub fix {
  die "eek!";
}

package main;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix;
use Catmandu::Importer::Mock;
use Catmandu::Util qw(:is);

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Bind::maybe';
    use_ok $pkg;
}
require_ok $pkg;

my $monad = Catmandu::Fix::Bind::maybe->new();
my $f     = sub { $_[0]->{demo}  = 1 ; $_[0] };
my $g     = sub { $_[0]->{demo} += 1 ; $_[0] };

is_deeply $monad->bind( $monad->unit({}), $f) , $f->({}) , "left unit monadic law";
is_deeply $monad->bind( $monad->unit({}), sub { $monad->unit(shift) }) , $monad->unit({}) , "right unit monadic law";
is_deeply $monad->bind( $monad->bind( $monad->unit({}), $f ) , $g )  ,
          $monad->bind( $monad->unit({}) , sub { $monad->bind($f->($_[0]),$g) } ) , "associative monadic law";

my $fixes =<<EOF;
do maybe()
  add_field(foo,bar)
end
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok $fixer , 'create fixer';

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing add_field';

$fixes =<<EOF;
do maybe()
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing zero fix functions';

$fixes =<<EOF;
do maybe()
  unless exists(foo)
  	add_field(foo,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {foo => 'bar'} , 'testing unless';

$fixes =<<EOF;
do maybe()
  if exists(foo)
  	add_field(foo2,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', foo2 => 'bar'} , 'testing if';

$fixes =<<EOF;
do maybe()
  reject exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok !defined $fixer->fix({foo => 'bar'}) , 'testing reject';

$fixes =<<EOF;
do maybe()
  select exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing select';

$fixes =<<EOF;
do maybe()
 do maybe()
  do maybe()
   add_field(foo,bar)
  end
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'testing nesting';

$fixes =<<EOF;
do maybe()
  throw_error()
  add_field(foo,bar)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'} , 'specific testing';

done_testing 14;