#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Validator::Simple';
    use_ok $pkg;
}

require_ok $pkg;

my $v = Catmandu::Validator::Simple->new(handler => sub { $_[0]->{field} eq '1' ? undef :
   'Not 1'});;

can_ok $v, 'validate_data';

throws_ok { $v->new(handler => 1) } qr/handler should be a CODE reference/;

my $rec = {field => 1};

is $v->validate($rec), $rec,'validate - success' ;

is $v->validate({field => 3}), undef, 'validate - fails';

is_deeply $v->last_errors, ['Not 1'], 'last_errors returns error message';

done_testing 7;
