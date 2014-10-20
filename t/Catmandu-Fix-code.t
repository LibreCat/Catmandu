#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Catmandu::Importer::Mock;
use Catmandu::Util qw(:is);

use_ok 'Catmandu::Fix::code';

sub hello {
    my ($data) = @_;
    $data->{hello} = 'world';
    $data;
}

my $fixer = Catmandu::Fix::code->new( \&hello );
is_deeply $fixer->fix({}), { hello => 'world' }, 'code fixer';

my $importer = Catmandu::Importer::Mock->new( size => 1, fix => [$fixer]);
is_deeply $importer->first, { n => 0, hello => 'world' }, 'fix as instance';

$importer = Catmandu::Importer::Mock->new( size => 1, fix => [\&hello]);
is_deeply $importer->first, { n => 0, hello => 'world' }, 'fix as code';

done_testing;
