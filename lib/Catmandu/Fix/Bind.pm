package Catmandu::Fix::Bind;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Moo::Role;
use Package::Stash;
use namespace::clean;

with 'Catmandu::Logger';

requires 'unit';
requires 'bind';

has __return__ => (is => 'rw', default => sub {[0]});
has __fixes__  => (is => 'rw', default => sub {[]});

around bind => sub {
    my ($orig, $self, $prev, @args) = @_;
    my $next = $orig->($self, $prev, @args);

    if ($self->can('plus')) {
        return $self->plus($prev, $next);
    }
    else {
        return $next;
    }
};

sub unit {
    my ($self, $data) = @_;
    return $data;
}

sub bind {
    my ($self, $data, $code) = @_;
    return $code->($data);
}

sub emit {
    my ($self, $fixer, $label) = @_;
    my $perl = "";

    my $var      = $fixer->var;
    my $bind_var = $fixer->capture($self);
    my $unit     = $fixer->generate_var;

    #---The subfixer is only provided for backwards compatibility
    # with older Bind implementations and is deprecated
    my $sub_fixer = Catmandu::Fix->new(fixes => $self->__fixes__);
    my $sub_fixer_var = $fixer->capture($sub_fixer);

    #---

    my $fix_stash = Package::Stash->new('Catmandu::Fix');
    my $fix_emit_reject;
    my $fix_emit_fixes;

    # Allow Bind-s to overwrite the default reject behavior
    if ($self->can('reject')) {
        $fix_emit_reject = $fix_stash->get_symbol('&emit_reject');
        $fix_stash->add_symbol(
            '&emit_reject' => sub {"return ${bind_var}->reject(${var});";});
    }

    # Allow Bind-s to bind to all fixes in if-unless-else statements
    unless ($self->does('Catmandu::Fix::Bind::Group')) {
        $fix_emit_fixes = $fix_stash->get_symbol('&emit_fixes');
        $fix_stash->add_symbol(
            '&emit_fixes' => sub {
                my ($this, $fixes) = @_;
                my $perl = '';

                $perl .= "my ${unit} = ${bind_var}->unit(${var});";

                for (my $i = 0; $i < @{$fixes}; $i++) {
                    my $fix           = $fixes->[$i];
                    my $name          = ref($fix);
                    my $var           = $this->var;
                    my $original_code = $this->emit_fix($fix);
                    my $generated_code
                        = "sub { my ${var} = shift; $original_code ; ${var} }";
                    $perl
                        .= "${unit} = ${bind_var}->bind(${unit}, $generated_code, '$name',${sub_fixer_var});";
                }

                if ($self->can('result')) {
                    $perl .= "${unit} = ${bind_var}->result(${unit});";
                }

                if ($self->__return__) {
                    $perl .= "${var} = ${unit};";
                }

                $perl;
            }
        );
    }

    $perl .= "my ${unit} = ${bind_var}->unit(${var});";

# If this is a Bind::Group, then all fixes are executed as one block in a bind
    if ($self->does("Catmandu::Fix::Bind::Group")) {
        my $generated_code = "sub { my ${var} = shift;";

        for my $fix (@{$self->__fixes__}) {
            my $original_code = $fixer->emit_fix($fix);
            $generated_code .= "$original_code ;";
        }

        $generated_code .= "${var} }";

        $perl
            .= "${unit} = ${bind_var}->bind(${unit}, $generated_code,'::group::',${sub_fixer_var});";
    }

#  If this isn't a Bind::Group, then bind will be executed for each seperate fix
    else {
        for my $fix (@{$self->__fixes__}) {
            my $name          = ref($fix);
            my $original_code = $fixer->emit_fix($fix);
            my $generated_code
                = "sub { my ${var} = shift; $original_code ; ${var} }";

            $perl
                .= "${unit} = ${bind_var}->bind(${unit}, $generated_code,'$name',${sub_fixer_var});";
        }
    }

    if ($self->can('result')) {
        $perl .= "${unit} = ${bind_var}->result(${unit});";
    }

    if ($self->__return__) {
        $perl .= "${var} = ${unit};";
    }

    $fix_stash->add_symbol('&emit_reject' => $fix_emit_reject)
        if $fix_emit_reject;
    $fix_stash->add_symbol('&emit_fixes' => $fix_emit_fixes)
        if $fix_emit_fixes;

    $perl;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Bind - a wrapper for Catmandu::Fix-es

=head1 SYNOPSIS

  package Catmandu::Fix::Bind::demo;
  use Moo;
  with 'Catmandu::Fix::Bind';

  sub bind {
    my ($self,$data,$code,$name) = @_;
    warn "executing $name";
    $code->($data);
  }

  # in your fix script you can now write
  do
     demo()

     fix1()
     fix2()
     fix3()
  end

  # this will execute all the fixes as expected, and print to STDERR the following messages

  executing fix1
  executing fix2
  executing fix3

=head1 DESCRIPTION

Bind is a package that wraps Catmandu::Fix-es and other Catmandu::Bind-s together. This gives
the programmer further control on the excution of fixes. With Catmandu::Fix::Bind you can simulate
the 'before', 'after' and 'around' modifiers as found in Moo or Dancer.

To wrap Fix functions, the Fix language introduces the 'do' statement:

  do BIND
     FIX1
     FIX2
     FIX3
  end

where BIND is a implementation of Catmandu::Fix::Bind and FIX1,...,FIXn are Catmandu::Fix functions.

In the example above the BIND will wrap FIX1, FIX2 and FIX3. BIND will first wrap the record data
using its 'unit' method and send the data sequentially to each FIX which can make inline changes
to the record data. In pseudo-code this will look like:

  $bind_data = $bind->unit($data);
  $bind_data = $bind->bind($bind_data, $fix1);
  $bind_data = $bind->bind($bind_data, $fix2);
  $bind_data = $bind->bind($bind_data, $fix3);
  return $data;

 An alternative form exists, 'doset' which will overwrite the record data with results of the last
 fix.

  doset BIND
        FIX1
        FIX2
        FIX3
  end

Will result in a pseudo code like:

  $bind_data = $bind->unit($data);
  $bind_data = $bind->bind($bind_data, $fix1);
  $bind_data = $bind->bind($bind_data, $fix2);
  $bind_data = $bind->bind($bind_data, $fix3);
  return $bind_data;

A Catmandu::Fix::Bind needs to implement two methods: 'unit' and 'bind'.

=head1 METHODS

=head2 unit($data)

The unit method receives a Perl $data HASH and should return it, possibly converted to a new type.
The 'unit' method is called before all Fix methods are executed. A trivial, but verbose, implementation
of 'unit' is:

  sub unit {
      my ($self,$data) = @_;
      my $wrapped_data = $data;
      return $wrapped_data;
  }

=head2 bind($wrapped_data,$code)

The bind method is executed for every Catmandu::Fix method in the fix script. It receives the $wrapped_data
(wrapped by 'unit'), the fix method as anonymous subroutine and the name of the fix. It should return data
with the same type as returned by 'unit'.
A trivial, but verbose, implementaion of 'bind' is:

  sub bind {
    my ($self,$wrapped_data,$code) = @_;
    my $data = $wrapped_data;
    $data = $code->($data);
    # we don't need to wrap it again because the $data and $wrapped_data have the same type
    $data;
  }

=head1 REQUIREMENTS

Bind modules are simplified implementations of Monads. They should answer the formal definition of Monads, codified
in 3 monadic laws:

=head2 left unit: unit acts as a neutral element of bind

   my $monad = Catmandu::Fix::Bind->demo();

   # bind(unit(data), coderef) == unit(coderef(data))
   $monad->bind( $monad->unit({foo=>'bar'}) , $coderef) == $monad->unit($coderef->({foo=>'bar'}));

=head2 right unit: unit act as a neutral element of bind

   # bind(unit(data), unit) == unit(data)
   $monad->bind( $monad->unit({foo=>'bar'}) , sub { $monad->unit(shift) } ) == $monad->unit({foo=>'bar'});

=head2 associative: chaining bind blocks should have the same effect as nesting them

   # bind(bind(unit(data),f),g) == bind(unit(data), sub { return bind(unit(f(data)),g) } )
   my $f = sub { my $data = shift; $data->{demo} = 1 ; $data };
   my $g = sub { my $data = shift; $data->{demo} += 1 ; $data};

   $monad->bind( $monad->bind( $monad->unit({}) , f ) , g ) ==
     $monad->bind( $monad->unit({}) , sub { my $data = shift; $monad->bind($monad->unit($f->($data)), $g ); $data; });

=head1 SEE ALSO

L<Catmandu::Fix::Bind::identity>, L<Catmandu::Fix::Bind::benchmark>

=cut
