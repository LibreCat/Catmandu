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
    $pkg = 'Catmandu::Cmd::data';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

{ 
    my $result = test_app(qq|Catmandu::CLI| => [
        qw(data --from-importer YAML --from-file t/catmandu.yml --into-exporter JSON)
    ]);

    my $perl = decode_json($result->stdout);

    ok $perl, 'got JSON';
    is $perl->[0]->{importer}{default}{package}, 'YAML', 'got data';
    is $result->error, undef, 'threw no exceptions' ;
}

{
    my $result = test_app(qq|Catmandu::CLI| => [
        qw(
            data
            --from-store test
            --from-bag data
            --into-exporter JSON
            --into-line-delimited 1
            --limit 1
            --fix t/myfixes.fix
        )
    ]);

    my @lines = split(/\n/, $result->stdout);

    ok @lines == 1, 'test limit';

    my $perl = decode_json($lines[0]);

    ok $perl, 'got JSON';
    is $perl->{value}, 'Sol', 'got data';
    is $perl->{utf8_name}, 'ვეპხის ტყაოსანი შოთა რუსთაველი', 'got utf8 data';
    is $result->error, undef, 'threw no exceptions';
}

{
    my $result = test_app(qq|Catmandu::CLI| => [ qw(delete test) ]);

    is $result->stdout, "" , 'got data';
    is $result->error, undef, 'threw no exceptions';
}

{
    my $result = test_app(qq|Catmandu::CLI| => [
        qw(data -v --from-importer CSV --from-file t/planets.csv --into-store Hash --into-bag data)
    ]);

    like $result->stderr, qr/added 4 objects/, 'imported 4 objects';
    is $result->error, undef, 'threw no exceptions';
}

done_testing;

