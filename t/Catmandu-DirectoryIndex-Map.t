#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp;
use File::Spec;
use Cwd;
use Path::Tiny;

my $pkg;

BEGIN {
    $pkg = "Catmandu::DirectoryIndex::Map";
    use_ok $pkg;
}

require_ok $pkg;
require_ok "Catmandu::Store::Hash";

my $t = File::Temp->newdir(EXLOCK => 0, UNLINK => 1);
my $dir = Cwd::abs_path($t->dirname);

ok(
    $pkg->new(base_dir => $dir, store_name => "Hash", bag_name => "data")
        ->bag()->does("Catmandu::Bag"),
    "bag must be Catmandu::Bag (1)"
);
ok(
    $pkg->new(base_dir => $dir, bag => Catmandu::Store::Hash->new()->bag())
        ->bag()->does("Catmandu::Bag"),
    "bag must be Catmandu::Bag (2)"
);

my $p;

lives_ok(
    sub {
        $p = $pkg->new(
            base_dir   => $dir,
            store_name => "Hash",
            bag_name   => "data"
        );
    }
);

my $a;

lives_ok(
    sub {
        $a = $p->add("a");
    }
);

lives_ok(
    sub {
        $b = $p->add("b");
    }
);

ok(        ref($a) eq "HASH"
        && $a->{_id} eq "a"
        && index($a->{_path}, $dir) == 0
        && index($a->{_path}, "0cc175b9c0f1b6a831c399e269772661")
        == (length($a->{_path}) - 32));

ok(        ref($b) eq "HASH"
        && $b->{_id} eq "b"
        && index($b->{_path}, $dir) == 0
        && index($b->{_path}, "92eb5ffee6ae2fec3ad71c777531578f")
        == (length($b->{_path}) - 32));

is_deeply $p->get("a"), $a;
is_deeply $p->get("b"), $b;

is_deeply $p->to_array, [ $a, $b ];

lives_ok( sub {
    $p->delete("a");
});

is_deeply $p->to_array, [ $b ];

lives_ok( sub {
    $p->delete_all;
} );

is_deeply $p->to_array, [];

done_testing;
