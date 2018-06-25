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
        $b = $p->add("/a and b/");
    }
);

my @a_parts = File::Spec->splitdir( $a->{_path} );

ok(        ref($a) eq "HASH"
        && $a->{_id} eq "a"
        && index($a->{_path}, $dir) == 0
        && $a_parts[-1] eq "a");

my @b_parts = File::Spec->splitdir( $b->{_path} );

ok(        ref($b) eq "HASH"
        && $b->{_id} eq "/a and b/"
        && index($b->{_path}, $dir) == 0
        && $b_parts[-1] eq "%2Fa%20and%20b%2F");

is_deeply $p->get("a"), $a;
is_deeply $p->get("/a and b/"), $b;

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
