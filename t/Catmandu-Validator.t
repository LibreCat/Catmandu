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

    sub validate_hash {
        $_[1]->{field} =~ /^1|7$/  ? undef : ["Value is not 1"] }

}

throws_ok { Role::Tiny->apply_role_to_package('T::ValidatorWithoutValidateOne', $pkg) } qr/missing validate_hash/;

my $e = T::Validator->new;

can_ok $e, 'is_valid';
can_ok $e, 'validate';
can_ok $e, 'validate_many';

# throw:: TODO make sure it is a hash for single one.
throws_ok { $e->validate(1) } qr/Cannot validate data of this type/;
throws_ok { $e->validate_many(1) } qr/Cannot validate data of this type/;
#
my $href0 = { field => 0 };
my $href1 = { field => 1 };

is $e->validate($href1), $href1;
is $e->validate($href0), undef;

is_deeply($e->last_errors, ['Value is not 1']);

is $e->is_valid($href1), 1;
is $e->is_valid($href0), 0;

my $after_callback_called =0;
is $e->validate_many($href1, {after_callback => sub { $after_callback_called = 1, $_[0]}}), $href1;
is $after_callback_called, 1;

my $arr =
  $e->validate_many([{field => 2},{field => 1}, {field => 0},{field => 3} ]);


is $e->count_valid, 1;
is $e->count_invalid, 3;

my $error_field = '_validation_errors';
my $validation_error_message = "Value is not 1";
my $e_efield = T::Validator->new( error_field =>1 ); #_validation_errors
is_deeply $e_efield->validate_many([{field => 5},{field => 3}, {field => 1}]),
    [
        {field => 5, $error_field => [$validation_error_message]},
        {field => 3, $error_field => [$validation_error_message]},
        {field => 1}
    ];

my $error_field_new = 'my_error';
is_deeply $e_efield->validate_many(
    [{field => 6},{field => 3}, {field => 1}],
    {error_field => $error_field_new },
),
    [
        {field => 6, $error_field_new => [$validation_error_message]},
        {field => 3, $error_field_new => [$validation_error_message]},
        {field => 1}
    ];


#test after_callback

my @invalid_array;

my $validator = T::Validator->new(
    after_callback => sub {
        my ($hashref, $errors) = @_;
        if ($errors) {
            $hashref->{errors} = $errors;
            push @invalid_array, $hashref;
            return;
        } else {
            $hashref->{valid} = 1;
        }
        $hashref;        
    } );
    
my $passed_array = $validator->validate_many(
    [{field => 3},{field => 1}, {field => 2}]
);

is_deeply $passed_array, [{field => 1, valid=>1}];
is_deeply \@invalid_array, [
    {field => 3, errors => [$validation_error_message]},
    {field => 2, errors => [$validation_error_message]}, 
     ];



#test error_callback
my $x=0;
@invalid_array =();
$validator = T::Validator->new( error_callback => sub { push @invalid_array, $_[0] } );
$passed_array = $validator->validate_many(
    [{field => 1},{field => 8}, {field => 9}]
);
is_deeply $passed_array, [{field => 1}];
is_deeply \@invalid_array, [{field => 8}, {field => 9}];

# test iterator

my $it = Catmandu::ArrayIterator->new([{field => 1},{field=>8},{field=>7}]);
$validator = T::Validator->new;
my $new_it = $validator->validate_many($it);
is_deeply $new_it->to_array, [{field => 1}, {field=>7}];

done_testing 24;
