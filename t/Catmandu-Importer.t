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
        state $fh = $self->fh;
        return sub {
            my $name = $self->readline;
            return defined $name ? { "hello" => $name } : undef;
        };
    }
}

my $i = T::Importer->new;
ok $i->does('Catmandu::Iterable');

$i = T::Importer->new( file => \"World" );
is_deeply $i->to_array, [{ hello => "World"}], 'import from string reference';

$i = T::Importer->new( file => \"Hello\nWorld" );
is $i->readall, "Hello\nWorld", "import all";

done_testing;

