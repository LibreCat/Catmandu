#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Util;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Interactive';
    use_ok $pkg;
}
require_ok $pkg;

{
    my $cmd = "\\q\n";
    my $res = "";
    my $in  = Catmandu::Util::io \$cmd, mode => 'r';
    my $out = Catmandu::Util::io \$res, mode => 'w';

    my $app = Catmandu::Interactive->new(in => $in, out => $out, silent => 1);

    $app->run();

    is $res , "", 'can execute \q';

    $in->close();
    $out->close();
}

{
    my $cmd = "add_field(hello,world)\n";
    my $res = "";
    my $in  = Catmandu::Util::io \$cmd, mode => 'r';
    my $out = Catmandu::Util::io \$res, mode => 'w';

    my $app = Catmandu::Interactive->new(
        in            => $in,
        out           => $out,
        silent        => 1,
        exporter      => 'JSON',
        exporter_args => {line_delimited => 1},
    );

    $app->run();

    is $res , "{\"hello\":\"world\"}\n", 'can execute hello world';

    $in->close();
    $out->close();
}

{
    my $cmd
        = "add_field(hello,world)\nif exists(hello)\nupcase(hello)\nend\n";
    my $res = "";
    my $in  = Catmandu::Util::io \$cmd, mode => 'r';
    my $out = Catmandu::Util::io \$res, mode => 'w';

    my $app = Catmandu::Interactive->new(
        in            => $in,
        out           => $out,
        silent        => 1,
        exporter      => 'JSON',
        exporter_args => {line_delimited => 1},
    );

    $app->run();

    is $res , "{\"hello\":\"world\"}\n{\"hello\":\"WORLD\"}\n",
        'can execute hello world with continuation';

    $in->close();
    $out->close();
}

{
    my $cmd = "add_field(hello,world)\n\\h\n";
    my $res = "";
    my $in  = Catmandu::Util::io \$cmd, mode => 'r';
    my $out = Catmandu::Util::io \$res, mode => 'w';

    my $app = Catmandu::Interactive->new(
        in            => $in,
        out           => $out,
        silent        => 1,
        exporter      => 'JSON',
        exporter_args => {line_delimited => 1},
    );

    $app->run();

    is $res , "{\"hello\":\"world\"}\nadd_field(hello,world)\n",
        'can execute \h';

    $in->close();
    $out->close();
}

{
    my $cmd = "add_field(hello.\$append,world)\n\\r\n";
    my $res = "";
    my $in  = Catmandu::Util::io \$cmd, mode => 'r';
    my $out = Catmandu::Util::io \$res, mode => 'w';

    my $app = Catmandu::Interactive->new(
        in            => $in,
        out           => $out,
        silent        => 1,
        exporter      => 'JSON',
        exporter_args => {line_delimited => 1},
    );

    $app->run();

    is $res , "{\"hello\":[\"world\"]}\n{\"hello\":[\"world\",\"world\"]}\n",
        'can execute \r';

    $in->close();
    $out->close();
}

done_testing;
