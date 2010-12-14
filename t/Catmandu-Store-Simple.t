use Test::More tests => 11;
use Test::Moose;
use Test::Exception;
use File::Spec;
use File::Temp;

BEGIN { use_ok 'Catmandu::Store::Simple'; }
require_ok 'Catmandu::Store::Simple';

my $tmp = File::Temp->newdir;
my $path = File::Spec->catfile($tmp->dirname, 'store.db');

my $store = Catmandu::Store::Simple->new(path => $path);
note "store path is $path";

 isa_ok $store, Catmandu::Store::Simple;
does_ok $store, Catmandu::Store;

my $obj = {
    name    => 'test',
    num     => 3.1415926536 ,
    colors  => [qw(red green blue)],
    authors => [
        { name => "Albert" ,
          last_name => "Einstein",
          theory => [qw(relativity quantum heat)] },
        { name => "Paul" ,
          last_name => "Dirac",
          theory => [qw(quantum)] },
    ],
};

is_deeply $store->save($obj), $obj;

is_deeply $store->load($obj->{_id}), $obj;

my $n = $store->each(sub { is_deeply $_[0], $obj });

is $n, 1;

throws_ok { $store->delete({missing => '_id'}) } qr/Missing/;

$store->delete($obj);

is $store->load($obj->{_id}), undef;
is $store->each(sub {}), 0;

done_testing;

