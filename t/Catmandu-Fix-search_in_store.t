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

{

    package Catmandu::Store::T::S::Bag;
    use Moo;
    use Catmandu::Sane;
    use Catmandu::Hits;
    use Catmandu::Util qw(:is);
    use Data::UUID;

    has '_hash' => (is => 'rw', lazy => 1, default => sub {+{};});

    sub add {
        my ($self, $record) = @_;
        $record->{_id} ||= Data::UUID->new->create_str;
        $_[0]->_hash()->{$record->{_id}} = $record;
    }

    sub get {
        $_[0]->_hash()->{$_[1]};
    }

    sub generator {
        my $self = $_[0];
        sub {
            my $records;
            unless ($records) {
                $records = [map {+{%{$self->_hash()->{$_}}}}
                        sort keys %{$self->_hash()}];
            }
            shift @$records;
        };
    }

    sub delete {
        delete $_[0]->_hash()->{$_[1]};
    }

    sub delete_all {
        $_[0]->_hash(+{});
    }

    sub search {
        my ($self, %args) = @_;
        my $query = delete $args{query};
        my $start = delete $args{start};
        $start = is_natural($start) ? $start : 0;
        my $limit = delete $args{limit};
        $limit = is_natural($limit) ? $limit : 20;
        my $hash  = $self->_hash();
        my $total = 0;
        my @hits;

        for my $id (sort keys %$hash) {

            my $r = {%{$hash->{$id}}, _id => $id};
            my $match = 0;

            if ($query eq "") {
                $match = 1;
            }
            else {

                for my $key (keys %$r) {

                    if ($r->{$key} eq $query) {

                        $match = 1;
                        last;

                    }

                }
            }

            if ($match) {
                if ($total >= $start && $total < ($start + $limit)) {
                    push @hits, $r;
                }
                $total++;
            }

        }

        Catmandu::Hits->new(
            hits  => \@hits,
            start => $start,
            limit => $limit,
            total => $total
        );
    }
    sub searcher        { }
    sub delete_by_query { }

    with 'Catmandu::Bag', 'Catmandu::Searchable';

    package Catmandu::Store::T::S;
    use Moo;
    use Catmandu::Sane;
    with 'Catmandu::Store';
}

#store data
use_ok 'Catmandu';

Catmandu->config->{store} = {
    default => {package => "T::S", options => {}},
    db      => {package => "T::S", options => {}}
};

lives_ok(
    sub {
        my $bag     = Catmandu->store('db')->bag('sessions');
        my $records = [
            {
                _id        => "njfranck",
                first_name => "Nicolas",
                last_name  => "Franck"
            },
            {
                _id        => "phochste",
                first_name => "Patrick",
                last_name  => "Hochstenbach"
            },
            {
                _id        => "nsteenla",
                first_name => "Nicolas",
                last_name  => "Steenlant"
            },
            {
                _id        => "drmoreel",
                first_name => "Dries",
                last_name  => "Moreels"
            }
        ];
        $bag->add_many($records);
        $bag->commit;
    },
    "data initialized"
);

#now test package
{

    my $got = $pkg->new('sessions')->fix({sessions => 'njfranck'});
    my $expected
        = {sessions => {start => 0, limit => 20, total => 0, hits => []}};
    is_deeply $got, $expected, "search in default store with query";
}

{
    my $got
        = $pkg->new('sessions', store => 'db')->fix({sessions => 'njfranck'});
    my $expected
        = {sessions => {start => 0, limit => 20, total => 0, hits => []}};
    is_deeply $got, $expected, "search in store db, bag data with query";
}

{
    my $got = $pkg->new('sessions', store => 'db', bag => 'sessions')
        ->fix({sessions => 'njfranck'});
    my $expected = {
        sessions => {
            start => 0,
            limit => 20,
            total => 1,
            hits  => [
                {
                    _id        => "njfranck",
                    first_name => "Nicolas",
                    last_name  => "Franck"
                }
            ]
        }
    };
    is_deeply $got, $expected, "search in store db, bag sessions with query";
}

{
    my $got
        = $pkg->new('sessions', store => 'db', bag => 'sessions', limit => 2)
        ->fix({sessions => ''});
    my $expected = {
        sessions => {
            start => 0,
            limit => 2,
            total => 4,
            hits  => [
                {
                    _id        => "drmoreel",
                    first_name => "Dries",
                    last_name  => "Moreels"
                },
                {
                    _id        => "njfranck",
                    first_name => "Nicolas",
                    last_name  => "Franck"
                }
            ]
        }
    };
    is_deeply $got, $expected, "explicit limit";
}
{
    my $got = $pkg->new(
        'sessions',
        store => 'db',
        bag   => 'sessions',
        limit => 2,
        start => 2
    )->fix({sessions => ''});
    my $expected = {
        sessions => {
            start => 2,
            limit => 2,
            total => 4,
            hits  => [
                {
                    _id        => "nsteenla",
                    first_name => "Nicolas",
                    last_name  => "Steenlant"
                },
                {
                    _id        => "phochste",
                    first_name => "Patrick",
                    last_name  => "Hochstenbach"
                }
            ]
        }
    };
    is_deeply $got, $expected, "explicit start and limit";
}

done_testing 9;
