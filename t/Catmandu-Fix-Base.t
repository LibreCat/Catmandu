#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Base';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::FixBaseWithoutEmit;
    use Moo;

    package T::FixBase;
    use Moo;
    with $pkg;

    sub emit {
        '$_[0]->{fix} = "base"';
    }

    package T::UseFixBase;
    use Moo;
    T::FixBase->import(as => 'do_fix_base');
}

throws_ok { Role::Tiny->apply_role_to_package('T::FixBaseWithoutEmit', $pkg) } qr/missing emit/;

my $fb = T::FixBase->new;
can_ok $fb, 'fixer';
can_ok $fb, 'emit';
can_ok $fb, 'import';

isa_ok $fb->fixer, 'Catmandu::Fix';

is_deeply {fix => 'base'}, T::UseFixBase::do_fix_base({});

done_testing 8;

