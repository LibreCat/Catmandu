#!/usr/bin/env perl
use lib 't/lib';
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix;
use Catmandu::Importer::Mock;
use Cpanel::JSON::XS qw(decode_json);
use Catmandu::Util qw(:is);
use Capture::Tiny ':all';

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Bind::hashmap';
    use_ok $pkg;
}
require_ok $pkg;

my $fixes = <<EOF;
do hashmap()
  add_field(foo,bar)
end
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok $fixer , 'create fixer';

is_deeply $fixer->fix({}), {foo => 'bar'}, 'testing add_field';

$fixes = <<EOF;
do hashmap()
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'},
    'testing zero fix functions';

$fixes = <<EOF;
do hashmap()
  unless exists(foo)
    add_field(foo,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {foo => 'bar'}, 'testing unless';

$fixes = <<EOF;
do hashmap()
  if exists(foo)
    add_field(foo2,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', foo2 => 'bar'},
    'testing if';

$fixes = <<EOF;
do hashmap()
  select exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'testing select';

$fixes = <<EOF;
do hashmap()
 do hashmap()
  do hashmap()
   add_field(foo,bar)
  end
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'testing nesting';

$fixes = <<EOF;
add_field(before,ok)
do hashmap()
   add_field(inside,ok)
end
add_field(after,ok)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}),
    {foo => 'bar', before => 'ok', inside => 'ok', after => 'ok'},
    'before/after testing';

# Specific tests
{
    my ($stdout, $stderr, $exit) = capture {
        $fixes = <<EOF;
  do hashmap(exporter: CSV, join: ',')
   do identity()
    copy_field(isbn,key)
    copy_field(_id,value)
   end
  end
EOF
        $fixer = Catmandu::Fix->new(fixes => [$fixes]);
        $fixer->fix(
            [
                {_id => 1, isbn => '1234567890'},
                {_id => 2, isbn => '1234567890'},
                {_id => 3, isbn => '0987654321'},
            ]
        );
        undef($fixer);
    };

    my $exp = <<EOF;
_id,value
0987654321,3
1234567890,"1,2"
EOF

    is $stdout , $exp, 'grouping isbn join';
}

{
    my ($stdout, $stderr, $exit) = capture {
        $fixes = <<EOF;
  do hashmap(exporter: JSON, uniq: 1)
    copy_field(isbn,key)
    copy_field(_id,value)
  end
EOF
        $fixer = Catmandu::Fix->new(fixes => [$fixes]);
        $fixer->fix(
            [
                {_id => 1, isbn => '1234567890'},
                {_id => 2, isbn => '1234567890'},
                {_id => 3, isbn => '0987654321'},
            ]
        );
        undef($fixer);
    };

    my $exp
        = '[{"_id":"0987654321","value":["3"]},{"_id":"1234567890","value":["1","2"]}]';

    is_deeply decode_json($stdout), decode_json($exp), 'grouping isbn uniq';
}

{
    my ($stdout, $stderr, $exit) = capture {
        $fixes = <<EOF;
  do hashmap(exporter: CSV, count: 1)
    copy_field(isbn,key)
    copy_field(_id,value)
  end
EOF
        $fixer = Catmandu::Fix->new(fixes => [$fixes]);
        $fixer->fix(
            [
                {_id => 1, isbn => '1234567890'},
                {_id => 2, isbn => '1234567890'},
                {_id => 3, isbn => '0987654321'},
            ]
        );
        undef($fixer);
    };

    my $exp = <<EOF;
_id,value
1234567890,2
0987654321,1
EOF

    is $stdout , $exp, 'grouping isbn count';
}

done_testing;
