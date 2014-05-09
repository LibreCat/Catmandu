#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Env';
    use_ok $pkg;
}
require_ok $pkg;

my $env = Catmandu::Env->new(load_paths => [qw(t/)]);

ok $env , qq|new|;
like $env->root , qr/t$/ , 'got root';
isa_ok $env->store , qq|Catmandu::Store::Hash| , qq|store()|;
isa_ok $env->store('hash') , qq|Catmandu::Store::Hash| , qq|store(hash)|;
isa_ok $env->fixer ,  qq|Catmandu::Fix| , qq|fixer|;
isa_ok $env->fixer('other') ,  qq|Catmandu::Fix| , qq|fixer(other)|;
isa_ok $env->importer ,  qq|Catmandu::Importer::YAML| , qq|importer()|;
isa_ok $env->importer('mock') ,  qq|Catmandu::Importer::Mock| , qq|importer(mock)|;
isa_ok $env->exporter ,  qq|Catmandu::Exporter::YAML| , qq|importer()|;
isa_ok $env->exporter('csv') , qq|Catmandu::Exporter::CSV| , qq|importer(csv)|;

done_testing 12;