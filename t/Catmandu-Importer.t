#!/usr/bin/env perl

use strict;
use warnings;
use v5.10.1;
use Test::More;
use Test::Exception;
use Test::LWP::UserAgent;
use HTTP::Response;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer';
    use_ok $pkg;
}
require_ok $pkg;

{

    package T::Importer;
    use Moo;
    with $pkg;

    sub generator {
        my ($self) = @_;
        sub {
            state $fh = $self->fh;
            my $name = $self->fh->getline;
            return defined $name ? {"hello" => $name} : undef;
        };
    }

    package T::DataPathImporter;
    use Moo;
    with $pkg;

    sub generator {
        my ($self) = @_;
        sub {
            state $data = [
                {abc => [{a => 1}, {b => 2}, {c => 3}]},
                {abc => [{d => 4}, {e => 5}, {f => 6}]}
            ];
            return shift @$data;
        };
    }
}

my $i = T::Importer->new;
ok $i->does('Catmandu::Iterable');
ok $i->can('_http_client'), 'provides a http client for internal use';

$i = T::Importer->new(file => \"World");
is_deeply $i->to_array, [{hello => "World"}], 'import from string reference';
is_deeply $i->to_array, [], 'importers can only iterate once';

$i = T::Importer->new(file => \"Hello\nWorld");
is join('', $i->fh->getlines), "Hello\nWorld", "import all";

$i = T::Importer->new(file => "missing");
throws_ok {$i->fh->getlines} "Catmandu::BadArg",
    "throws an error if file doesn't exist";

$i = T::DataPathImporter->new;
is_deeply $i->to_array,
    [
    {abc => [{a => 1}, {b => 2}, {c => 3}]},
    {abc => [{d => 4}, {e => 5}, {f => 6}]}
    ];
$i = T::DataPathImporter->new(data_path => 'abc');
is_deeply $i->to_array,
    [[{a => 1}, {b => 2}, {c => 3}], [{d => 4}, {e => 5}, {f => 6}]];
$i = T::DataPathImporter->new(data_path => 'abc.*');
is_deeply $i->to_array,
    [{a => 1}, {b => 2}, {c => 3}, {d => 4}, {e => 5}, {f => 6}];

$i = T::Importer->new(user_agent => user_agent(), file => 'http://demo.org/');
is join('', $i->fh->getlines), "test123", "read from http (file)";

$i = T::Importer->new(
    user_agent => user_agent(),
    file       => 'http://demo.org/{id}',
    variables  => {id => 1234}
);
is $i->file, "http://demo.org/1234";
is join('', $i->fh->getlines), "test1234",
    "read from http (file + variables)";

$i = T::Importer->new(
    user_agent => user_agent(),
    file       => 'http://demo.org/{1},{2},{3}',
    variables  => [qw(red green blue)]
);
is $i->file, "http://demo.org/red,green,blue";
is join('', $i->fh->getlines), "RED-GREEN-BLUE",
    "read from http (file + variables list)";

$i = T::Importer->new(
    user_agent => user_agent(),
    file       => 'http://demo.org/{1},{2},{3}',
    variables  => "red,green,blue"
);
is $i->file, "http://demo.org/red,green,blue";
is join('', $i->fh->getlines), "RED-GREEN-BLUE",
    "read from http (file + variables list)";

$i = T::Importer->new(
    user_agent  => user_agent(),
    file        => 'http://demo.org/post',
    http_method => 'POST',
    http_body   => '=={id}==',
    variables   => {id => 1234}
);
is $i->file, "http://demo.org/post";
is join('', $i->fh->getlines), "POST",
    "read from http (file + variables list + post request)";

$i = T::Importer->new(
    user_agent  => user_agent(),
    file        => 'http://demo.org/post',
    http_method => 'POST',
    http_body   => '=={id}==',
    variables   => "red,green,blue"
);
is $i->file, "http://demo.org/post";
is join('', $i->fh->getlines), "POST",
    "read from http (file + variables list + post request)";

$i = T::Importer->new(
    user_agent  => user_agent(),
    file        => 'http://demo.org/not-exsists',
    http_method => 'POST',
    http_body   => '=={id}==',
    variables   => "red,green,blue"
);

throws_ok {$i->fh->getlines} 'Catmandu::HTTPError',
    "throws an error on non-existing pages";

$i = T::Importer->new(file => 'http://demo.org');

is ref($i->_http_client), 'LWP::UserAgent', 'Got a real client';

# http retry
$i = T::Importer->new(
    user_agent => user_agent(),
    file       => 'http://demo.org/retry',
);

throws_ok {$i->fh->getline} 'Catmandu::HTTPError';

$i = T::Importer->new(
    user_agent => user_agent(),
    file       => 'http://demo.org/retry',
    http_retry => 1,
);

throws_ok {$i->fh->getline} 'Catmandu::HTTPError';

$i = T::Importer->new(
    user_agent => user_agent(),
    file       => 'http://demo.org/retry',
    http_retry => 2,
);

lives_ok {$i->fh->getline};

$i = T::Importer->new(
    user_agent  => user_agent(),
    file        => 'http://demo.org/retry',
    http_timing => '1',
);

throws_ok {$i->fh->getline} 'Catmandu::HTTPError';

$i = T::Importer->new(
    user_agent  => user_agent(),
    file        => 'http://demo.org/retry',
    http_timing => '1,1',
);

lives_ok {$i->fh->getline};

done_testing;

sub user_agent {
    my $ua = Test::LWP::UserAgent->new(agent => 'Test/1.0');

    $ua->map_response(
        qr{^http://demo\.org/$},
        HTTP::Response->new(
            '200', 'OK', ['Content-Type' => 'text/plain'], 'test123'
        )
    );

    $ua->map_response(
        qr{^http://demo\.org/1234$},
        HTTP::Response->new(
            '200', 'OK', ['Content-Type' => 'text/plain'], 'test1234'
        )
    );

    $ua->map_response(
        qr{^http://demo\.org/red,green,blue$},
        HTTP::Response->new(
            '200',                            'OK',
            ['Content-Type' => 'text/plain'], 'RED-GREEN-BLUE'
        )
    );

    $ua->map_response(
        qr{^http://demo\.org/post$},
        HTTP::Response->new(
            '200', 'OK', ['Content-Type' => 'text/plain'], 'POST'
        )
    );

    my $tries = 0;
    $ua->map_response(
        qr{^http://demo\.org/retry$},
        sub {
            $tries += 1;
            if ($tries < 3) {
                HTTP::Response->new(
                    '408',
                    'Request Timeout',
                    ['Content-Type' => 'text/plain'], 'GET'
                );
            }
            else {
                HTTP::Response->new('200', 'OK',
                    ['Content-Type' => 'text/plain'], 'GET');
            }

        }
    );

    $ua;
}

