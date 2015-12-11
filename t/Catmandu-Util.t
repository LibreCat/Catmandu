#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::Handle;

use utf8;
use feature 'state';

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Util';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::ImportNothing;
    use Catmandu::Util;
    package T::ImportAll;
    use Catmandu::Util qw(:all);
    package T::ImportIs;
    use Catmandu::Util qw(:is);
    package T::ImportCheck;
    use Catmandu::Util qw(:check);
    package T::ImportMisc;
    use Catmandu::Util qw(:misc);
    package T::ImportIo;
    use Catmandu::Util qw(:io);
    package T::ImportData;
    use Catmandu::Util qw(:data);
    package T::ImportArray;
    use Catmandu::Util qw(:array);
    package T::ImportHash;
    use Catmandu::Util qw(:hash);
    package T::ImportString;
    use Catmandu::Util qw(:string);
    package T::ImportHuman;
    use Catmandu::Util qw(:human);
    package T::ImportXML;
    use Catmandu::Util qw(:xml);
}

for my $sym (qw(same different)) {
    can_ok $pkg, "is_$sym";
    can_ok $pkg, "check_$sym";
    can_ok 'T::ImportAll', "is_$sym";
    can_ok 'T::ImportAll', "check_$sym";
    ok !T::ImportNothing->can("is_$sym");
    ok !T::ImportNothing->can("check_$sym");
    can_ok 'T::ImportIs', "is_$sym";
    ok !T::ImportCheck->can("is_$sym");
    can_ok 'T::ImportCheck', "check_$sym";
    ok !T::ImportIs->can("check_$sym");
}
for my $sym (qw(able instance invocant ref
        scalar_ref array_ref hash_ref code_ref regex_ref glob_ref
        value string number integer natural positive)) {
    can_ok $pkg, "is_$sym";
    can_ok $pkg, "is_maybe_$sym";
    can_ok $pkg, "check_$sym";
    can_ok $pkg, "check_maybe_$sym";
    can_ok 'T::ImportAll', "is_$sym";
    can_ok 'T::ImportAll', "is_maybe_$sym";
    can_ok 'T::ImportAll', "check_$sym";
    can_ok 'T::ImportAll', "check_maybe_$sym";
    ok !T::ImportNothing->can("is_$sym");
    ok !T::ImportNothing->can("is_maybe_$sym");
    ok !T::ImportNothing->can("check_$sym");
    ok !T::ImportNothing->can("check_maybe_$sym");
    can_ok 'T::ImportIs', "is_$sym";
    can_ok 'T::ImportIs', "is_maybe_$sym";
    ok !T::ImportCheck->can("is_$sym");
    ok !T::ImportCheck->can("is_maybe_$sym");
    can_ok 'T::ImportCheck', "check_$sym";
    can_ok 'T::ImportCheck', "check_maybe_$sym";
    ok !T::ImportIs->can("check_$sym");
    ok !T::ImportIs->can("check_maybe_$sym");

    # autovivication test
    my $arr_ref  = [];
    my $hash_ref = { arr_ref => $arr_ref };
    my $name     = "is_$sym";
    my $sub_ref  = do {
        no strict 'refs';
        \&{"Catmandu::Util::$name"};
    };
    $sub_ref->($hash_ref->{arr_ref}->[@$arr_ref]);
    is_deeply $hash_ref, { arr_ref => [] } , "no autovivication in $name";
}

for my $sym (qw(require_package use_lib)) {
    can_ok $pkg, $sym;
    ok !T::ImportNothing->can($sym);
    can_ok 'T::ImportAll', $sym;
    can_ok 'T::ImportMisc', $sym;
}
for my $sym (qw(io read_file read_yaml read_json)) {
    can_ok $pkg, $sym;
    ok !T::ImportNothing->can($sym);
    can_ok 'T::ImportAll', $sym;
    can_ok 'T::ImportIo', $sym;
}
for my $sym (qw(parse_data_path get_data set_data delete_data data_at)) {
    can_ok $pkg, $sym;
    ok !T::ImportNothing->can($sym);
    can_ok 'T::ImportAll', $sym;
    can_ok 'T::ImportData', $sym;
}
for my $sym (qw(array_exists array_group_by array_pluck array_to_sentence
        array_sum array_includes array_any array_uniq array_split)) {
    can_ok $pkg, $sym;
    ok !T::ImportNothing->can($sym);
    can_ok 'T::ImportAll', $sym;
    can_ok 'T::ImportArray', $sym;
}
for my $sym (qw(hash_merge)) {
    can_ok $pkg, $sym;
    ok !T::ImportNothing->can($sym);
    can_ok 'T::ImportAll', $sym;
    can_ok 'T::ImportHash', $sym;
}
for my $sym (qw(as_utf8 trim capitalize)) {
    can_ok $pkg, $sym;
    ok !T::ImportNothing->can($sym);
    can_ok 'T::ImportAll', $sym;
    can_ok 'T::ImportString', $sym;
}
for my $sym (qw(human_number human_content_type human_byte_size)) {
    can_ok $pkg, $sym;
    ok !T::ImportNothing->can($sym);
    can_ok 'T::ImportAll', $sym;
    can_ok 'T::ImportHuman', $sym;
}
for my $sym (qw(xml_declaration xml_escape)) {
    can_ok $pkg, $sym;
    ok !T::ImportNothing->can($sym);
    can_ok 'T::ImportAll', $sym;
    can_ok 'T::ImportXML', $sym;
}

{
    my $coderef = sub {
        state $counter = 0;
        return "Count: $counter\n" if $counter++ < 5; 
    };

    my $io = Catmandu::Util::io($coderef, mode => 'r');

    ok $io , 'io from code_ref read';
    is $io->getline() , "Count: 1\n" , 'getline';
}

{
    my $coderef = sub {
        my $line = shift;
        return 1;
    };

    my $io = Catmandu::Util::io($coderef, mode => 'w');

    ok $io , 'io from code_ref write';
    ok $io->print("Test") , 'print';
}


{
    my $io = Catmandu::Util::io(IO::File->new("< Changes"));

    ok $io , 'io IO::Handle instance';
}

{
    use Math::BigRat;
    throws_ok { Catmandu::Util::io(Math::BigRat->new('3/7')) } 'Catmandu::BadArg' , 'got Catmandu::BadArg';
}

{
    my $test =<<EOF;
На берегу пустынных волн
Стоял он, дум великих полн,
И вдаль глядел. Пред ним широко
Река неслася; бедный чёлн
По ней стремился одиноко.
По мшистым, топким берегам
Чернели избы здесь и там,
Приют убогого чухонца;
И лес, неведомый лучам
В тумане спрятанного солнца,
Кругом шумел.
EOF
    chop($test);
    is Catmandu::Util::read_file("t/russian.txt") , $test , 'read_file';
}

{
    my $test =<<EOF;
На берегу пустынных волн
Стоял он, дум великих полн,
И вдаль глядел. Пред ним широко
Река неслася; бедный чёлн
По ней стремился одиноко.
По мшистым, топким берегам
Чернели избы здесь и там,
Приют убогого чухонца;
И лес, неведомый лучам
В тумане спрятанного солнца,
Кругом шумел.
EOF
    chop($test);
    my $io = IO::File->new("< t/russian.txt");
    is Catmandu::Util::read_io($io) , $test , 'read_io';
}

{
    my $test =<<EOF;
На берегу пустынных волн
Стоял он, дум великих полн,
И вдаль глядел. Пред ним широко
Река неслася; бедный чёлн
По ней стремился одиноко.
По мшистым, топким берегам
Чернели избы здесь и там,
Приют убогого чухонца;
И лес, неведомый лучам
В тумане спрятанного солнца,
Кругом шумел.
EOF
    chop($test);
    
    my $filename = "$$.txt";
    ok Catmandu::Util::write_file($filename,$test) ,'write_file';
    is Catmandu::Util::read_file($filename) , $test , 'read_file';
    unlink $filename;
}

{
    is_deeply Catmandu::Util::read_yaml("t/small.yaml") , { "hello" => "ვეპხის ტყაოსანი შოთა რუსთაველი"} , 'read_yaml';
}

{
    is_deeply Catmandu::Util::read_json("t/small.json") , { "hello" => "ვეპხის ტყაოსანი შოთა რუსთაველი"} , 'read_json';
}

is Catmandu::Util::join_path("/this/..","./is","..","./a/../weird/path","./../../isnt/../it") , "/it" , 'join_path';
is Catmandu::Util::normalize_path("/this/../is/../a/../weird/path/../../isnt/../it") , "/it" , 'normalize_path';
is Catmandu::Util::segmented_path("12345678",segment_size =>2,base_path=>"/x") , "/x/12/34/56/78" , 'segmented_path';

is_deeply [Catmandu::Util::parse_data_path("foo.bar.x")] , [ ['foo','bar'], "x" ] , "parse_data_path";

is Catmandu::Util::get_data({ foo => 'bar'} , 'foo') , 'bar' , 'get_data(foo)';
is Catmandu::Util::get_data([qw(0 1 2)], 1) , '1' , 'get_data(1)';
is Catmandu::Util::get_data([qw(0 1 2)], '$first') , '0' , 'get_data($first)';
is Catmandu::Util::get_data([qw(0 1 2)], '$last') , '2' , 'get_data($last)';
is_deeply [Catmandu::Util::get_data([qw(0 1 2)], '*')] , [qw(0 1 2)] , 'get_data(*)';

{ 
    my $data = { foo => 'bar'};
    Catmandu::Util::set_data($data,'foo','bar2');
    is_deeply $data , { foo => 'bar2' } , 'set_data 1';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::set_data($data, 0, 'bar');
    is_deeply $data , [qw(bar 1 2)] , 'set_data 2';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::set_data($data, '$first', 'bar');
    is_deeply $data , [qw(bar 1 2)] , 'set_data 3';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::set_data($data, '$last', 'bar');
    is_deeply $data , [qw(0 1 bar)] , 'set_data 4';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::set_data($data, '$prepend', 'bar');
    is_deeply $data , [qw(bar 0 1 2)] , 'set_data 5';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::set_data($data, '$append', 'bar');
    is_deeply $data , [qw(0 1 2 bar)] , 'set_data 6';
}

{ 
    my $data = { foo => 'bar'};
    Catmandu::Util::set_data($data,'foo','bar2');
    is_deeply $data , { foo => 'bar2' } , 'set_data 1';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::set_data($data, 0, 'bar');
    is_deeply $data , [qw(bar 1 2)] , 'set_data 2';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::set_data($data, '$first', 'bar');
    is_deeply $data , [qw(bar 1 2)] , 'set_data 3';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::set_data($data, '$last', 'bar');
    is_deeply $data , [qw(0 1 bar)] , 'set_data 4';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::set_data($data, '$prepend', 'bar');
    is_deeply $data , [qw(bar 0 1 2)] , 'set_data 5';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::set_data($data, '$append', 'bar');
    is_deeply $data , [qw(0 1 2 bar)] , 'set_data 6';
}

{ 
    my $data = { foo => 'bar'};
    Catmandu::Util::delete_data($data,'foo');
    is_deeply $data , { } , 'delete_data 1';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::delete_data($data, 0);
    is_deeply $data , [qw(1 2)] , 'delete_data 2';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::delete_data($data, '$first');
    is_deeply $data , [qw(1 2)] , 'delete_data 3';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::delete_data($data, '$last');
    is_deeply $data , [qw(0 1)] , 'delete_data 4';
}

{ 
    my $data = [qw(0 1 2)];
    Catmandu::Util::delete_data($data, '*');
    is_deeply $data , [] , 'delete_data 5';
}

is Catmandu::Util::data_at('foo', { foo => 'bar'}) , 'bar' , 'data_at 1';
is Catmandu::Util::data_at('foo.1', { foo => [qw(bar bar2 bar3)] }) , 'bar2' , 'data_at 2';
is Catmandu::Util::data_at('foo.$first', { foo => [qw(bar bar2 bar3)] }) , 'bar' , 'data_at 3';
is Catmandu::Util::data_at('foo.$last', { foo => [qw(bar bar2 bar3)] }) , 'bar3' , 'data_at 4';

ok Catmandu::Util::array_exists([qw(0 1 2)],0) , 'array_exists 1';
ok ! Catmandu::Util::array_exists([qw(0 1 2)],3) , '!array_exists';

is_deeply Catmandu::Util::array_group_by([
      { color => 'red'   , number => 1} ,
      { color => 'blue'  , number => 2} ,
      { color => 'green' , number => 3} ,
      { number => 4}
    ] , 'color') , {
      red   => [{ color => 'red'   , number => 1}] ,
      blue  => [{ color => 'blue'  , number => 2}] ,
      green => [{ color => 'green' , number => 3}] ,
    } , 'array_group_by';

is_deeply Catmandu::Util::array_pluck([ { id => 1 } , { foo => 2 } , { id => 3}] , 'id') , [ 1, undef, 3] , 'array_pluck';

is Catmandu::Util::array_sum([1,2,3,4,5,6,7,8,9,10]) , 55 , 'array_sum';

ok Catmandu::Util::array_includes([{ foo => [ { bar => 1}]}] ,  {foo => [ { bar => 1}]} ) , 'array_includes';

ok Catmandu::Util::array_any([0,1,2], sub { return 1 if shift == 2}) , 'array_any';

is_deeply Catmandu::Util::array_rest([0,1,2]) , [1,2] , 'array_rest';

is_deeply Catmandu::Util::array_uniq([0,1,2,2,2,2,3,3,2,3]) , [0,1,2,3] , 'array_uniq';

is Catmandu::Util::capitalize("école") , "École" , 'capitalize';

is Catmandu::Util::human_number(64354) , "64,354" , 'human_number';

is Catmandu::Util::human_byte_size(10) , "10 bytes" , 'human_byte_size';
is Catmandu::Util::human_byte_size(10005) , "10.01 KB" , 'human_byte_size';
is Catmandu::Util::human_byte_size(10005000) , "10.01 MB" , 'human_byte_size';
is Catmandu::Util::human_byte_size(10005000000) , "10.01 GB" , 'human_byte_size';

is Catmandu::Util::human_content_type('application/x-dos_ms_excel') , 'Excel' , 'human_content_type';

is Catmandu::Util::xml_declaration() , qq(<?xml version="1.0" encoding="UTF-8"?>\n) , 'xml_declaration';

is Catmandu::Util::xml_escape("<>'&") , '&lt;&gt;&apos;&amp;' , 'xml_escape';

done_testing 534;