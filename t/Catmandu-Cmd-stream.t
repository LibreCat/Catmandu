#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester::CaptureExternal;
use Cpanel::JSON::XS;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Cmd::stream';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

note("download");
{
    my $result = test_app(
        qq|Catmandu::CLI| => [
            qw(stream File::Simple --root t/data2 --keysize 9 --bag 1 --id test.txt to -)
        ]
    );

#    is $result->stdout , "钱唐湖春行\n";

    is $result->error, undef, 'threw no exceptions';
}

note("upload");
{
    my $result = test_app(
        qq|Catmandu::CLI| => [
            qw(stream cpanfile to File::Simple --root t/data  --keysize 9 --bag 456 --id test.txt)
        ]
    );

    ok !$result->stdout;

    is $result->error, undef, 'threw no exceptions';

    ok -f "t/data/000/000/456/test.txt", "found the correct file";

    unlink "t/data/000/000/456/test.txt";
}

done_testing;
