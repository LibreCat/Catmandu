#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;
use Cwd;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::PathIndex';
    use_ok $pkg;
}

require_ok $pkg;

{

    package T::PathIndexNoGet;
    use Moo;
    sub add        { }
    sub delete     { }
    sub delete_all { }

    sub generator {
        sub { }
    }

    package T::PathIndexNoAdd;
    use Moo;
    sub get        { }
    sub delete     { }
    sub delete_all { }

    sub generator {
        sub { }
    }

    package T::PathIndexNoDelete;
    use Moo;
    sub add        { }
    sub get        { }
    sub delete_all { }

    sub generator {
        sub { }
    }

    package T::PathIndexNoDeleteAll;
    use Moo;
    sub add    { }
    sub get    { }
    sub delete { }

    sub generator {
        sub { }
    }

    package T::PathIndexNoGenerator;
    use Moo;
    sub add        { }
    sub get        { }
    sub delete     { }
    sub delete_all { }

    package T::PathIndex;
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

throws_ok {Role::Tiny->apply_role_to_package("T::PathIndexNoGet", $pkg)}
qr/missing get/, "method get missing";

throws_ok {Role::Tiny->apply_role_to_package("T::PathIndexNoAdd", $pkg)}
qr/missing add/, "method add missing";

throws_ok {Role::Tiny->apply_role_to_package("T::PathIndexNoDelete", $pkg)}
qr/missing delete/, "method delete missing";

throws_ok {
    Role::Tiny->apply_role_to_package("T::PathIndexNoDeleteAll", $pkg)
}
qr/missing delete_all/, "method delete_all missing";

throws_ok {
    Role::Tiny->apply_role_to_package("T::PathIndexNoGenerator", $pkg)
}
qr/missing generator/, "method generator missing";

dies_ok(sub {T::PathIndex->new();}, "new without base_dir should fail");

lives_ok(sub {T::PathIndex->new(base_dir => Cwd::cwd());},
    "new with base_dir should succeed");

can_ok(T::PathIndex->new(base_dir => Cwd::cwd()), "base_dir");

done_testing;
