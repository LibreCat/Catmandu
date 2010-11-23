use Test::More tests => 11;
use Test::Moose;
use Test::Exception;
use IO::All;
use Data::UUID;

BEGIN { use_ok 'Catmandu::Store::Simple'; }
require_ok 'Catmandu::Store::Simple';

my $file = io->catfile(io->tmpdir->pathname, Data::UUID->new->create_str)->name;

my $store = Catmandu::Store::Simple->new(file => $file);
note "store path is $file";

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

throws_ok { $store->delete({missing => '_id'}) } qr/Missing _id/;

$store->delete($obj);

is $store->load($obj->{_id}), undef;
is $store->each(sub {}), 0;

done_testing;

