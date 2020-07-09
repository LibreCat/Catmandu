package Catmandu::Fix::Condition::in;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

has path1 => (fix_arg => 1);
has path2 => (fix_arg => 1);

with 'Catmandu::Fix::Condition::Builder';

sub _build_tester {
    my ($self)       = @_;
    my $path1_getter = as_path($self->path1)->getter;
    my $path2_getter = as_path($self->path2)->getter;
    sub {
        my $data  = $_[0];
        my $vals1 = $path1_getter->($data);
        my $vals2 = $path2_getter->($data);
        return 0 unless @$vals1 && @$vals2 && @$vals1 == @$vals2;
        for (my $i = 0; $i < @$vals1; $i++) {
            no if $] >= 5.018, warnings => 'experimental::smartmatch';
            return 0 unless $vals1->[$i] ~~ $vals2->[$i];
        }
        return 1;
    }
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
