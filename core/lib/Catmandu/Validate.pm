package Catmandu::Validate;

use strict;
use warnings;
use Scalar::Util qw(blessed);
use Carp;
use Exporter qw(import);
our @EXPORT_OK = qw(validate);

sub new {
  my ($pkg,%args) = @_;
  bless \%args, $pkg;
}

sub _parse_args {
   my (@args) = @_;

   if (@args < 2) {
    Carp::croak("Catmandu::Validate requires at least two arguments");
   }

   my $self;
   if (blessed $args[0]) {
      $self = shift @args;

      if (@args == 1) {
        @args = (schema => $self->{schema} ,
                 obj    => $args[0]);
      } else {
        push(@args, schema => $self->{schema});
      }
   } else {
      $self = Catmandu::Validate->new();
      if (@args == 2) {
        @args = (obj => $args[0],
                 schema => $args[1]);
      }
   }

   return ($self,@args);
}

sub validate {
   my ($self,%args) = &_parse_args(@_);
   my $obj    = $args{obj};
   my $schema = $args{schema};

   Carp::croak("Catmandu::Validate requires an object") unless defined $obj;
   Carp::croak("Catmandu::Validate requires a schema") unless defined $schema;

   #TODO - execute the validation
   
   return $obj;
}
   
1;

__END__

=head1 NAME

 Catmandu::Validate - A Catmandu object validator

=head1 SYNOPSIS

 use Catmandu::Validate qw(validate);

 my $result = validate(obj => $obj, schema => $schema);

or

 use Catmandu::Validate;

 my $validator = Catmandu::Validate->new(schema => $schema);
 my $result = $validator->validate(obj => $obj); 

=head1 METHODS

=over 4

=item validate(obj => $obj [, schema => $schema]) 

Validate a Catmandu Perl data object against a schema. Can be called as a function
or a method. Requires a Validation schema (to be defined). Returns the parsed
object on success, dies with warnings on error.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
