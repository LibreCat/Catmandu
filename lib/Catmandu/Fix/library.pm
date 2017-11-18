package Catmandu::Fix::library;

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has module => (fix_arg => 1);

sub BUILD {
    my ($self, $args) = @_;

    my $pkg = Catmandu::Util::require_package($args->{module});

    for my $module ($pkg->manifest) {
      $module =~ s{^$pkg\::}{};
      my $orig  = $pkg . '::' . $module;
      my $alias = 'Catmandu::Fix::' . $module;
      Catmandu::Util::alias_package($orig,$alias);
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

   # Import fixes methods from an external library
   library("foobar")

   # Use the methods from the 'foobar' library
   foobar_method1()
   foobar_method2()
   ...

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
