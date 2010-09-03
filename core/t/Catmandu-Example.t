use Test::More tests => 6;
use Test::Exception;

BEGIN { use_ok('Catmandu::Example'); }
require_ok('Catmandu::Example');

my $obj = Catmandu::Example->new;

is(ref $obj, 'Catmandu::Example', 'new');
is($obj->ok, 1, 'obj->ok');
is($obj->fail, 0, 'obj->fail');
throws_ok { $obj->throw } qr/aargh/ , 'obj->throw';
