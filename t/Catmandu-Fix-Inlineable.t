#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Inlineable';
    use_ok $pkg;
}
require_ok $pkg;

{

    package T::FixBase;
    use Moo;
    with $pkg;

    sub fix {
        my ($self,$data) = @_;

        $data->{foo} = 'bar';

        $data;
    }

    package T::UseFixBase;
    use Moo;
    T::FixBase->import(as => 'do_fix_base');
}

my $fb = T::FixBase->new;
can_ok $fb, 'fix';
can_ok $fb, 'import';

is_deeply {foo => 'bar'}, T::UseFixBase::do_fix_base({}) , 'can inline';

done_testing 5;
