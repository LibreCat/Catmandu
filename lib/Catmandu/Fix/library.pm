package Catmandu::Fix::library;

use Moo;
use namespace::clean;
use Catmandu::Util;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has module => (fix_arg => 1);
has as     => (fix_opt => 1);

sub BUILD {
    my ($self, $args) = @_;

    my $module = $args->{module};
    my $as     = $args->{as};

    my $pkg = Catmandu::Util::require_package($module);

    for my $part ($pkg->manifest) {
      $part     =~ s{^$pkg\::}{};
      my $orig  = $pkg . '::' . $part ;

      if (Catmandu::Util::is_string($as)) {
          if ($part =~ /^Condition::(\S+)/) {
              $part = "Condition::$as\::$1";
          }
          elsif ($part =~ /^Bind::(\S+)/) {
              $part = "Bind::$as\::$1";
          }
          else {
              $part = "$as\::$part";
          }
      }

      my $alias = 'Catmandu::Fix::' . $part ;

      Catmandu::Util::alias_package($orig,$alias, brave => 1) unless ($orig eq $alias);
    }
}

sub emit {
    my ($self, $fixer, $label) = @_;
    "last ${label};";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::library - import fixes, conditions and binds from an external library

=head1 SYNOPSIS

   # Import fixes, conditions and binds from an external libraries
   library("foobar")

   # Use the methods from the 'foobar' library
   method1()
   method2()
   ...

   # Import with a pkg name
   library("foobar",as:foo)
   foo::method1()
   foo::method2()

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
