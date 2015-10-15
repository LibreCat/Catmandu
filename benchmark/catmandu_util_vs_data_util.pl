#!/usr/bin/env perl

use strict;
use warnings;
use Benchmark qw(:all);
use Catmandu::Util ();
use Data::Util ();

my @names = qw(
    is_invocant 
    is_scalar_ref
    is_array_ref
    is_hash_ref
    is_code_ref
    is_regex_ref
    is_glob_ref
    is_value
    is_string
    is_number
    is_integer
);

my @catmandu_util_subs = (
    \&Catmandu::Util::is_invocant, 
    \&Catmandu::Util::is_scalar_ref,
    \&Catmandu::Util::is_array_ref,
    \&Catmandu::Util::is_hash_ref,
    \&Catmandu::Util::is_code_ref,
    \&Catmandu::Util::is_regex_ref,
    \&Catmandu::Util::is_glob_ref,
    \&Catmandu::Util::is_value,
    \&Catmandu::Util::is_string,
    \&Catmandu::Util::is_number,
    \&Catmandu::Util::is_integer,
);

my @data_util_subs = (
    \&Data::Util::is_invocant,
    \&Data::Util::is_scalar_ref,
    \&Data::Util::is_array_ref,
    \&Data::Util::is_hash_ref,
    \&Data::Util::is_code_ref,
    \&Data::Util::is_regex_ref,
    \&Data::Util::is_glob_ref,
    \&Data::Util::is_value,
    \&Data::Util::is_string,
    \&Data::Util::is_number,
    \&Data::Util::is_integer,
);

my $str = "a string";
my $regex = qr//;
my @data = (
    'Benchmark', 
    \$str, 
    [], 
    {}, 
    sub {}, 
    $regex, 
    \*STDIN, 
    "", 
    $str, 
    1.1,
    1,
);

for (my $i = 0; $i < @names; $i++) {
    my $name = $names[$i];
    my $catmandu_util_sub = $catmandu_util_subs[$i];
    my $data_util_sub = $data_util_subs[$i];
    cmpthese(1000000, {
        "Catmandu::Util::$name" => sub { $catmandu_util_sub->($_) for @data }, 
        "Data::Util::$name" => sub { $data_util_sub->($_) for @data },      
    });
}

