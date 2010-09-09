#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;
use JSON;
use IO::String;

BEGIN { use_ok 'Catmandu::Exporter::JSON'; }
require_ok 'Catmandu::Exporter::JSON';

our $list = [{'a' => 'moose'}, {'a' => 'pony'}, {'a' => 'shrimp'}];
our $hash = {'a' => {'deeply' => {'nested' => $list}}};

package NoEach;
sub new { bless {}, shift }

package Each;
sub new { bless {}, shift }

sub each {
    my ($self, $sub) = @_;
    foreach my $obj (@$list) {
        $sub->($obj);
    }
}

package main;

my $json;
my $file = IO::String->new($json);

my $exporter = Catmandu::Exporter::JSON->open($file);

isa_ok $exporter, 'Catmandu::Exporter::JSON';

throws_ok { $exporter->write("1") } qr/Can't export/, 'write string';
throws_ok { $exporter->write(1) } qr/Can't export/, 'write integer';
throws_ok { $exporter->write() } qr/Can't export/, 'write undef';
throws_ok { $exporter->write(NoEach->new) } qr/Can't export/, 'write no each';

$exporter->write($list);
is_deeply $list, decode_json($json);

$file->truncate(0);

$exporter->write($hash);
is_deeply $hash, decode_json($json);

$file->truncate(0);

$exporter->write(Each->new);
is_deeply $list, decode_json($json);

