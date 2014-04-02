#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Log::Any::Test;
use Log::Any::Adapter;
use Data::Dumper;

my $pkg;
BEGIN {
    $pkg = 'Catmandu';
    use_ok $pkg;
}
require_ok $pkg;

# Logging ----------------------------
Log::Any::Adapter->set('Test');

isa_ok(Catmandu->log,'Log::Any::Adapter::Test', 'logger test');

Catmandu->log->debug('debug test');
Catmandu->log->info('info test');
Catmandu->log->warn('warn test');

Catmandu->log->contains_ok(qr/debug test/,'debug log');
Catmandu->log->contains_ok(qr/info test/,'info log');
Catmandu->log->contains_ok(qr/warn test/,'info log');

# Default_load_path ------------------
ok(my $curr_path = Catmandu->default_load_path, 'get current path');

Catmandu->default_load_path('/tmp');
is(Catmandu->default_load_path, '/tmp', 'got default_load_path');

Catmandu->default_load_path($curr_path);
is(Catmandu->default_load_path, $curr_path, 'got default_load_path 2');

# Load
Catmandu->load;
is(Catmandu->config->{test}, 'ok', 'load and conf test');

is(Catmandu->default_store,'default','default store');
is(Catmandu->default_fixer,'default','default fixer');
is(Catmandu->default_importer,'default','default importer');
is(Catmandu->default_exporter,'default','default exporter');

isa_ok(Catmandu->importer,'Catmandu::Importer::YAML','importer test');
isa_ok(Catmandu->importer('mock'),'Catmandu::Importer::Mock','importer test');
isa_ok(Catmandu->exporter,'Catmandu::Exporter::YAML','exporter test');
isa_ok(Catmandu->exporter('csv'),'Catmandu::Exporter::CSV','exporter test');
isa_ok(Catmandu->store,'Catmandu::Store::Hash','store test');
isa_ok(Catmandu->store('hash'),'Catmandu::Store::Hash','store test');
isa_ok(Catmandu->fixer,'Catmandu::Fix','fixer test');

like(Catmandu->export_to_string({ foo => 'bar'}, 'JSON'),qr/{"foo":"bar"}/,'export_to_string');

done_testing 22;
