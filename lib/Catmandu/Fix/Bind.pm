package Catmandu::Fix::Bind;

use Moo::Role;
use namespace::clean;

requires 'unit';
requires 'bind';

has fixes => (is => 'rw', default => sub { [] });

sub unit {
	my ($self,$data) = @_;
	return $data;
}

sub bind {
	my ($self,$data,$code,$name) = @_;
	return $code->($data);
}

sub emit {
    my ($self, $fixer, $label) = @_;
    my $perl = "";

    my $binder = $fixer->binder // [];

    push @$binder , $self;
    $fixer->binder($binder);

    $perl .= $fixer->emit_fixes($self->fixes);

    pop @$binder;
    $binder = undef if (@$binder == 0);

    $fixer->binder($binder);

    $perl;
}

=head1 NAME

Catmandu::Fix::Bind - a Binder for fixes

=head1 SYNOPSIS

  package Catmandu::Fix::Bind::Demo;
  use Moo;
  with 'Catmandu::Fix::Bind';

  sub bind {
    my $(self,$data,$code,$name) = @_;
    warn "executing $name";
    $code->($data);
  }

  package main;
  use Catmandu::Importer::JSON;
  use Catmandu::Fix;

  my $importer = Catmandu::Importer::JSON->new(file => 'test.data');
  my $fixer = Catmandu::Fix->new(
           fixes => ['add_field("foo","bar"); set_field("foo","test")'],
           binds => ['Demo']
  );

  # This will print:
  #   executing add_field
  #   executing set_field
  #   executing add_field
  #   executing set_field
  $fixer->fix($importer)->each(sub {});

=head1 DESCRIPTION

Bind is a package that wraps Catmandu::Fix-es and other Catmandu::Bind-s together. This gives
the programmer further control on the excution of fixes. With Catmandu::Fix::Bind you can simulate
the 'before', 'after' and 'around' modifiers as found in Moo. 

A Catmandu::Fix::Bind needs to implement two methods: 'unit' and 'bind'.

=head1 METHODS

=head2 unit($data)

The unit method receives a Perl $data HASH and should return it. The 'unit' method is called on a 
Catmandu::Fix::Bind instance before all Fix methods are executed. A trivial implementation of 'unit' is:

  sub unit {
      my ($self,$data) = @_;
      return $data;
  }

=head2 bind($data,$code,$name,$perl)

The bind method is executed for every Catmandu::Fix method in the fixer. It receives the $data
, which as wrapped by unit, the fix method as anonymous subroutine, the name of the fix and the actual perl
code to run it. It should return the fixed code. A trivial implementaion of 'bind' is:

  sub bind {
	  my ($self,$data,$code,$name) = @_;
	  return $code->($data);
  } 


=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
