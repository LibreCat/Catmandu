#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;
use Catmandu::ArrayIterator;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Validator';
    use_ok $pkg;
}
require_ok $pkg;

{

    package T::ValidatorWithoutValidateHash;
    use Moo;

    package T::Validator;
    use Moo;
    with $pkg;

    sub validate_data {
        $_[1]->{field} =~ /^1|7$/ ? undef : ["Value is not 1"];
    }

}

throws_ok {
    Role::Tiny->apply_role_to_package('T::ValidatorWithoutValidateOne', $pkg)
}
qr/missing validate_data/;

my $e = T::Validator->new;

can_ok $e, 'is_valid';
can_ok $e, 'validate';

# throw:: TODO make sure it is a hash for single one.
throws_ok {$e->validate(1)} qr/Cannot validate data of this type/;

#
my $href0 = {field => 0};
my $href1 = {field => 1};

is $e->validate($href1), $href1, 'validate() - success';
is $e->validate($href0), undef,  'validate() - fails';

is_deeply($e->last_errors, ['Value is not 1'], 'last_errors returns errors');

is $e->is_valid($href1), 1, 'is_valid returns 1';
is $e->is_valid($href0), 0, 'is_valid returns 0';

my $after_callback_called = 0;
$e = T::Validator->new(
    after_callback => sub {$after_callback_called = 1, $_[0]});
is $e->validate($href1),   $href1, 'validate, after_callback - success';
is $after_callback_called, 1,      'validate, after_callback - called';

my $arr
    = $e->validate([{field => 2}, {field => 1}, {field => 0}, {field => 3}]);

is $e->valid_count,   1, 'valid_count';
is $e->invalid_count, 3, 'invalid_count';

my $error_field              = '_validation_errors';
my $validation_error_message = "Value is not 1";
my $e_efield                 = T::Validator->new(error_field => 1);
is_deeply $e_efield->validate([{field => 5}, {field => 3}, {field => 1}]),
    [
    {field => 5, $error_field => [$validation_error_message]},
    {field => 3, $error_field => [$validation_error_message]},
    {field => 1}
    ],
    'validate, error_field 1';

my $error_field_new = 'my_error';

$e_efield = T::Validator->new(error_field => $error_field_new);

is_deeply $e_efield->validate([{field => 6}, {field => 3}, {field => 1}]),
    [
    {field => 6, $error_field_new => [$validation_error_message]},
    {field => 3, $error_field_new => [$validation_error_message]},
    {field => 1}
    ],
    'validate, error_field 2';

my @invalid_array;

my $validator = T::Validator->new(
    after_callback => sub {
        my ($hashref, $errors) = @_;
        if ($errors) {
            $hashref->{errors} = $errors;
            push @invalid_array, $hashref;
            return;
        }
        else {
            $hashref->{valid} = 1;
        }
        $hashref;
    }
);

my $passed_array
    = $validator->validate([{field => 3}, {field => 1}, {field => 2}]);

is_deeply $passed_array, [{field => 1, valid => 1}],
    'validate, after_callback - valid';
is_deeply \@invalid_array,
    [
    {field => 3, errors => [$validation_error_message]},
    {field => 2, errors => [$validation_error_message]},
    ],
    'validate, after_callback - invalid';

my $x = 0;
@invalid_array = ();
$validator
    = T::Validator->new(error_callback => sub {push @invalid_array, $_[0]});
$passed_array
    = $validator->validate([{field => 1}, {field => 8}, {field => 9}]);
is_deeply $passed_array, [{field => 1}],
    'validate (array) - valid records returned';
is_deeply \@invalid_array, [{field => 8}, {field => 9}],
    'validate - invalid records returned';

# test iterator

my $it = Catmandu::ArrayIterator->new(
    [{field => 1}, {field => 8}, {field => 7}]);
$validator = T::Validator->new;
my $new_it = $validator->validate($it);
is_deeply $new_it->to_array, [{field => 1}, {field => 7}],
    'validate (iterator) - iterator returned';

done_testing 22;
