#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;
use Cwd;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::DirectoryIndex';
    use_ok $pkg;
}

require_ok $pkg;

{

    package T::DirectoryIndexNoGet;
    use Moo;
    sub add        { }
    sub delete     { }
    sub delete_all { }

    sub generator {
        sub { }
    }

    package T::DirectoryIndexNoAdd;
    use Moo;
    sub get        { }
    sub delete     { }
    sub delete_all { }

    sub generator {
        sub { }
    }

    package T::DirectoryIndexNoDelete;
    use Moo;
    sub add        { }
    sub get        { }
    sub delete_all { }

    sub generator {
        sub { }
    }

    package T::DirectoryIndexNoDeleteAll;
    use Moo;
    sub add    { }
    sub get    { }
    sub delete { }

    sub generator {
        sub { }
    }

    package T::DirectoryIndexNoGenerator;
    use Moo;
    sub add        { }
    sub get        { }
    sub delete     { }
    sub delete_all { }

    package T::DirectoryIndex;
    use Moo;
    with $pkg;
    sub add        { }
    sub get        { }
    sub delete     { }
    sub delete_all { }

    sub generator {
        sub { }
    }

}

throws_ok {Role::Tiny->apply_role_to_package("T::DirectoryIndexNoGet", $pkg)}
qr/missing get/, "method get missing";

throws_ok {Role::Tiny->apply_role_to_package("T::DirectoryIndexNoAdd", $pkg)}
qr/missing add/, "method add missing";

throws_ok {Role::Tiny->apply_role_to_package("T::DirectoryIndexNoDelete", $pkg)}
qr/missing delete/, "method delete missing";

throws_ok {
    Role::Tiny->apply_role_to_package("T::DirectoryIndexNoDeleteAll", $pkg)
}
qr/missing delete_all/, "method delete_all missing";

throws_ok {
    Role::Tiny->apply_role_to_package("T::DirectoryIndexNoGenerator", $pkg)
}
qr/missing generator/, "method generator missing";

dies_ok(sub {T::DirectoryIndex->new();}, "new without base_dir should fail");

lives_ok(sub {T::DirectoryIndex->new(base_dir => Cwd::cwd());},
    "new with base_dir should succeed");

can_ok(T::DirectoryIndex->new(base_dir => Cwd::cwd()), "base_dir");

done_testing;
