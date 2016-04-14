#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::search_in_store';
    use_ok $pkg;
}

require_ok $pkg;

#store data
use_ok 'Catmandu::Store::Hash';
use_ok 'Catmandu::Store::Hash::Bag';
use_ok 'Catmandu';

Catmandu->config->{store} = {
    default => {
        package => "Catmandu::Store::Hash",
        options => {}
    },
    db => {
        package => "Catmandu::Store::Hash",
        options => {}
    }
};

lives_ok(sub {
    my $bag = Catmandu->store('db')->bag('sessions');
    my $records = [
        { _id => "njfranck", first_name => "Nicolas", last_name => "Franck" },
        { _id => "phochste", first_name => "Patrick", last_name => "Hochstenbach" },
        { _id => "nsteenla", first_name => "Nicolas", last_name => "Steenlant" },
        { _id => "drmoreel", first_name => "Dries", last_name => "Moreels" }
    ];
    $bag->add_many($records);
    $bag->commit;
}, "data initialized" );

#now test package
{

    my $got = $pkg->new('sessions')->fix({ sessions => 'njfranck' });
    my $expected = { sessions => { start => 0, limit => 20, total => 0, hits => [] } };
    is_deeply $got, $expected, "search in default store with query";
}

{
    my $got = $pkg->new('sessions','db')->fix({ sessions => 'njfranck' });
    my $expected = { sessions => { start => 0, limit => 20, total => 0, hits => [] } };
    is_deeply $got,$expected, "search in store db, bag data with query";
}

{
    my $got = $pkg->new('sessions','db', bag => 'sessions')->fix({ sessions => 'njfranck' });
    my $expected = { sessions => { start => 0, limit => 20, total => 1, hits => [ { _id => "njfranck", first_name => "Nicolas", last_name => "Franck" } ] } };
    is_deeply $got, $expected, "search in store db, bag sessions with query";
}

{
    my $got = $pkg->new('sessions','db', bag => 'sessions', limit => 2, sort => "_id asc")->fix({ sessions => '' });
    my $expected = {
        sessions => {
            start => 0,
            limit => 2,
            total => 4,
            hits => [
                { _id => "drmoreel", first_name => "Dries", last_name => "Moreels" },
                { _id => "njfranck", first_name => "Nicolas", last_name => "Franck" }
            ]
        }
    };
    is_deeply $got,$expected,"explicit limit";
}
{
    my $got = $pkg->new('sessions','db', bag => 'sessions', limit => 2, start => 2, sort => "_id asc")->fix({ sessions => '' });
    my $expected = {
        sessions => {
            start => 2,
            limit => 2,
            total => 4,
            hits => [
                { _id => "nsteenla", first_name => "Nicolas", last_name => "Steenlant" },
                { _id => "phochste", first_name => "Patrick", last_name => "Hochstenbach" }
            ]
        }
    };
    is_deeply $got,$expected, "explicit start and limit";
}

done_testing 11;
