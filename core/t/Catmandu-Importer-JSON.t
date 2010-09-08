#!/usr/bin/env perl

use strict;
use warnings;
use JSON;

use Test::More tests => 9;
use Test::Exception;

BEGIN { use_ok('Catmandu::Importer::JSON'); }
require_ok('Catmandu::Importer::JSON');

use Catmandu::Importer::JSON;

my $jsfile   = '/tmp/json.$$';
my $ref      = [
                { id => 1,
                  one => { deeply => { nested => { data => { structure => "ok" }}}}
                } ,
                { id => 2,
                  another => { deeply => { nested => { data => { structure => "ok" }}}}
                } ,
               ];

&dump($jsfile,$ref);

my $importer = Catmandu::Importer::JSON->open($jsfile);

isa_ok($importer, 'Catmandu::Importer::JSON', 'isa importer');

my $count = $importer->each(sub {
    my $obj = shift;
    like($obj->{id}, qr/^\d+/, 'got id');
    if ($obj->{id} == 1) {
      is_deeply($obj->{one}, $ref->[0]->{one}, 'deeply one');
    }
    elsif ($obj->{id} == 2) {
      is_deeply($obj->{another}, $ref->[1]->{another}, 'deeply one');
    }
});

is($count,2,'counting 2 objects');

is($importer->close,1,'close');

unlink $jsfile;

sub dump {
   my ($file,$ref) = @_;
   local(*F);
   open(F,">$file") || die "failed to open $file for writing";
   print F to_json($ref);
   close(F);
}
