use Test::More tests => 5;
use Test::Moose;

BEGIN { use_ok 'Catmandu::Fix::Null'; }
require_ok 'Catmandu::Fix::Null';

my $fixer = Catmandu::Fix::Null->new;

 isa_ok $fixer, Catmandu::Fix::Null;
does_ok $fixer, Catmandu::Fix;

my $obj = {
        name => {
             first => 'James' ,
             last  => 'Brown' ,
             deps => [
                { name => 'Alpha' } ,
                { name => 'Beta' }
             ]
        } ,
    };

my $n;

$n = $fixer->fix($obj);
is_deeply $n, $obj;

done_testing;

