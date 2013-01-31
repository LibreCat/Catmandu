#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

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
        array_sum array_includes array_any array_uniq)) {
    can_ok $pkg, $sym;
    ok !T::ImportNothing->can($sym);
    can_ok 'T::ImportAll', $sym;
    can_ok 'T::ImportArray', $sym;
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

done_testing 450;

