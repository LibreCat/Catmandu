#!/usr/bin/env perl
use lib 't/lib';
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

my $fixes = <<EOF;
do each(path:.,var:i)
  add_field(foo,bar)
end
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok $fixer , 'create fixer';

is_deeply $fixer->fix({ok => 1}), {ok => 1, foo => 'bar'},
    'testing add_field';

$fixes = <<EOF;
do each(path:.,var:i)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'},
    'testing zero fix functions';

$fixes = <<EOF;
do each(path:.,var:i)
  unless exists(foo)
  	add_field(foo,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({ok => 1}), {ok => 1, foo => 'bar'}, 'testing unless';

$fixes = <<EOF;
do each(path:.,var:i)
  if exists(foo)
  	add_field(foo2,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', foo2 => 'bar'},
    'testing if';

$fixes = <<EOF;
do each(path:.,var:i)
  reject exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok !defined $fixer->fix({foo => 'bar'}), 'testing reject';

$fixes = <<EOF;
do each(path:.,var:i)
  select exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'testing select';

$fixes = <<EOF;
do each(path:.,var:i)
 do each(path:.,var:i)
  do each(path:.,var:i)
   add_field(foo,bar)
  end
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'testing nesting';

$fixes = <<EOF;
add_field(before,ok)
do each(path:.,var:i)
   add_field(inside,ok)
end
add_field(after,ok)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}),
    {foo => 'bar', before => 'ok', inside => 'ok', after => 'ok'},
    'before/after testing';

$fixes = <<'EOF';
do each(path:demo, var: t)
 if all_match(t.key,en)
    copy_field(t.value, titles.$append)
 else
    upcase(t.key)
    upcase(t.value)
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix(
    {
        demo =>
            {nl => 'Tuin der lusten', en => 'The Garden of Earthly Delights'}
    }
    ),
    {
    demo => {NL => 'TUIN DER LUSTEN', en => 'The Garden of Earthly Delights'},
    titles => ['The Garden of Earthly Delights']
    },
    'specific testing';

$fixes = <<'EOF';
do each(path:demo)
 if all_match(key,en)
    copy_field(value, titles.$append)
 else
    upcase(key)
    upcase(value)
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix(
    {
        demo =>
            {nl => 'Tuin der lusten', en => 'The Garden of Earthly Delights'}
    }
    ),
    {
    demo => {
        NL     => 'TUIN DER LUSTEN',
        en     => 'The Garden of Earthly Delights',
        titles => ['The Garden of Earthly Delights']
    },
    },
    'specific testing 2';

done_testing;
