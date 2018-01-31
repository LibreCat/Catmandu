#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
#use Catmandu::Fix::set_field;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::validate';
    use_ok $pkg;
}

my $validator;
sub record { { name => { foo => 'bar' }, @_ } };

$validator = $pkg->new( '', 'Simple', handler => sub {});
is_deeply $validator->fix(record), record, "no errors";

$validator = $pkg->new( '', 'Simple', handler => sub { 'fail' });
is_deeply $validator->fix(record), record( errors => ['fail'] ), "errors";

$validator = $pkg->new( 'name', 'Simple',
    handler => sub { $_[0] },
    error_field => 'warnings',
);
is_deeply $validator->fix(record),
    record( warnings => [{ foo => 'bar'}] ),
    "got errors with error_field";

$validator = $pkg->new( '', 'Simple', handler => sub { [{},1,{}] });
 $validator->fix(record);

done_testing;
