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
    $pkg = 'Catmandu::DirectoryIndex::UUID';
    use_ok $pkg;
}

require_ok $pkg;

my $t = File::Temp->newdir(EXLOCK => 0, UNLINK => 1);
my $dir = Cwd::abs_path($t->dirname);

my $p;

lives_ok(
    sub {

        $p = $pkg->new(base_dir => $dir);

    }
);

dies_ok(
    sub {

        $p->add("test");

    },
    "ids must be valid UUID's"
);

lives_ok(
    sub {

        $p->add("11979D40-F504-11E7-AD0C-1F86AB14EC2F");

    },
    "valid UUID added"
);

lives_ok(
    sub {

        $p->add(lc("11979D40-F504-11E7-AD0C-1F86AB14EC2F"));

    },
    "UUID's are normalized to uppercase"
);

is_deeply(
    $p->get("11979D40-F504-11E7-AD0C-1F86AB14EC2F"),
    {
        _id   => "11979D40-F504-11E7-AD0C-1F86AB14EC2F",
        _path => File::Spec->catdir(
            $dir,  "119", "79D", "40-", "F50", "4-1", "1E7", "-AD",
            "0C-", "1F8", "6AB", "14E", "C2F"
        )
    },
    "get returns mapping"
);

$p->add("6998EBAE-CEE7-11E7-97D5-911D6EE4309A");

is_deeply(
    $p->to_array(),
    [
        {
            _id   => "11979D40-F504-11E7-AD0C-1F86AB14EC2F",
            _path => File::Spec->catdir(
                $dir,  "119", "79D", "40-", "F50", "4-1", "1E7", "-AD",
                "0C-", "1F8", "6AB", "14E", "C2F"
            )
        },
        {
            _id   => "6998EBAE-CEE7-11E7-97D5-911D6EE4309A",
            _path => File::Spec->catdir(
                $dir,  "699", "8EB", "AE-", "CEE", "7-1", "1E7", "-97",
                "D5-", "911", "D6E", "E43", "09A"
            )
        }
    ],
    "path index contains 2 mappings now"
);

lives_ok(
    sub {

        $p->delete("11979D40-F504-11E7-AD0C-1F86AB14EC2F");

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

path(File::Spec->catdir($dir2, qw(1 2 3 4 5 5 6 7 8 9 10 11 12 13)))
    ->mkpath();

dies_ok(
    sub {

        $pkg->new(base_dir => $dir2)->to_array();

    },
    "invalid mappings trigger an error"
);

done_testing;
