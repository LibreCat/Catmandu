package Catmandu::Fix::Condition::in;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path  => (fix_arg => 1);
has path2 => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleCompareTest';

sub emit_test {
    my ($self, $var, $var2, $fixer) = @_;
    "${var} ~~ ${var2}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::in - only execute fixes the data in one path is contained in another

=head1 SYNOPSIS

   #-------------------------------------------------------------------
   # Compare single values
   # foo => 42 , bar => 42 => in(foo,bar) -> true
   if in(foo,bar)
      add_field(forty_two,ok)
   end
   
   # When comparing single values to an array: test if the value is 
   # contained in the array  

   # foo => 1 , bar => [3,2,1]  => in(foo,bar) -> true
   if in(foo,bar)
      add_field(test,ok)
   end

   # foo => 42 , bar => [1,2,3] => in(foo,bar) -> false
   unless in(foo,bar)
      add_field(test,ok)
   end

   # In the following examples we'll write in pseudo code the true/false
   # values of some 'in()' comparissons

   # scalars vs arrays - check if the value is in the array
   foo: 42 , bar: [1,2,3]                   in(foo,bar) -> false
   foo: 1  , bar: [1,2,3]                   in(foo,bar) -> true

   # scalars vs hashes - check if the key is in the hash
   foo: name , bar: { name => 'Patrick' }           in(foo,bar) -> true
   foo: name , bar: { deep => {name => 'Nicolas'}}  in(foo,bar) -> false

   # array vs array - check if the contents is equal
   foo: [1,2] , bar: [1,2]                  in(foo,bar) -> true
   foo: [1,2] , bar: [1,2,3]                in(foo,bar) -> false
   foo: [1,2] , bar: [[1,2],3]              in(foo,bar) -> false

=head1 STATUS

Be aware this function is experimental in many perl versions

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
