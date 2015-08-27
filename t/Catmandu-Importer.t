#!/usr/bin/env perl

use strict;
use warnings;
use v5.10.1;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::Importer;
    use Moo;
    with $pkg;

    sub generator {
        my ($self) = @_;
        sub {
            state $fh = $self->fh;
            my $name = $self->readline;
            return defined $name ? { "hello" => $name } : undef;
        };
    }

    package T::DataPathImporter;
    use Moo;
    with $pkg;

    sub generator {
        my ($self) = @_;
        sub {
            state $data = [{abc => [{a=>1},{b=>2},{c=>3}]},
                           {abc => [{d=>4},{e=>5},{f=>6}]}];
            return shift @$data;
        };
    }
}

my $i = T::Importer->new;
ok $i->does('Catmandu::Iterable');

$i = T::Importer->new( file => \"World" );
is_deeply $i->to_array, [{ hello => "World"}], 'import from string reference';

$i = T::Importer->new( file => \"Hello\nWorld" );
is $i->readall, "Hello\nWorld", "import all";

$i = T::DataPathImporter->new;
is_deeply $i->to_array, [{abc => [{a=>1},{b=>2},{c=>3}]},{abc => [{d=>4},{e=>5},{f=>6}]}];
$i = T::DataPathImporter->new(data_path => 'abc');
is_deeply $i->to_array, [[{a=>1},{b=>2},{c=>3}],[{d=>4},{e=>5},{f=>6}]];
$i = T::DataPathImporter->new(data_path => 'abc.*');
is_deeply $i->to_array, [{a=>1},{b=>2},{c=>3},{d=>4},{e=>5},{f=>6}];

done_testing;

