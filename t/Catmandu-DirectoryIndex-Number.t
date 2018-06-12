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
    $pkg = 'Catmandu::DirectoryIndex::Number';
    use_ok $pkg;
}

require_ok $pkg;

my $t = File::Temp->newdir(EXLOCK => 0, UNLINK => 1);
my $dir = Cwd::abs_path($t->dirname);

dies_ok(
    sub {

        $pkg->new(base_dir => $dir, keysize => 1);

    },
    "keysize must be a multiple of 3"
);

my $p;

lives_ok(
    sub {

        $p = $pkg->new(base_dir => $dir, keysize => 9);

    }
);

dies_ok(
    sub {

        $p->add("test");

    },
    "ids must be natural numbers"
);

dies_ok(
    sub {

        $p->add(-1);

    },
    "ids must be bigger or equal to zero"
);

dies_ok(
    sub {

        $p->add(1234567890);

    },
    "ids must fit into configured keysize"
);

lives_ok(
    sub {

        $p->add(123456789);

    }
);

is_deeply(
    $p->get(123456789),
    {
        _id   => "123456789",
        _path => File::Spec->catdir($dir, "123", "456", "789")
    },
    "get returns mapping"
);

is_deeply(
    $p->add(1),
    {
        _id   => "000000001",
        _path => File::Spec->catdir($dir, "000", "000", "001")
    },
    "number are converted to left padded strings"
);

is_deeply(
    $p->add("000000002"),
    {
        _id   => "000000002",
        _path => File::Spec->catdir($dir, "000", "000", "002")
    },
    "left padded strings are ok if they respect the keysize"
);

is_deeply(
    $p->to_array(),
    [
        {
            _id   => "000000001",
            _path => File::Spec->catdir($dir, "000", "000", "001")
        },
        {
            _id   => "000000002",
            _path => File::Spec->catdir($dir, "000", "000", "002")
        },
        {
            _id   => "123456789",
            _path => File::Spec->catdir($dir, "123", "456", "789")
        },
    ],
    "path index contains 3 mappings now"
);

lives_ok(
    sub {

        $p->delete(2);

    },
    "delete directory"
);

lives_ok(
    sub {

        $p->delete_all();

    },
    "delete all directories"
);

is_deeply($p->to_array(), [], "list of entries should be empty now");

my $t2 = File::Temp->newdir(EXLOCK => 0, UNLINK => 1);
my $dir2 = Cwd::abs_path($t->dirname);

path(File::Spec->catdir($dir2, "a", "b", "c"))->mkpath();

dies_ok(
    sub {

        $pkg->new(base_dir => $dir2)->to_array();

    },
    "invalid mappings trigger an error"
);

done_testing;
