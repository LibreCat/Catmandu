#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Error';
    use_ok $pkg;
}
require_ok $pkg;

throws_ok { Catmandu::Error->throw("Oops!"); } 'Catmandu::Error' , qq|caught an error|;
throws_ok { Catmandu::Error->throw; } 'Catmandu::Error' , qq|caught an error with no message|;
is(Catmandu::Error->new->message, '' , qq|default error message is an empty string|);
throws_ok { Catmandu::BadVal->throw("Whoo!"); } 'Catmandu::BadVal' , qq|caught a badval|;
throws_ok { Catmandu::BadArg->throw("Aarrgh!"); } 'Catmandu::BadArg', qq|caught a badarg|;
throws_ok { Catmandu::BadArg->throw("Aarrgh!"); } 'Catmandu::BadArg', qq|caught a badarg|;
throws_ok { Catmandu::NotImplemented->throw("Huh?!"); } 'Catmandu::NotImplemented' , qq|caught a notimplemented|;

done_testing;
