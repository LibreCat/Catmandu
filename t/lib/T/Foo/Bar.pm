package T::Foo::Bar;
use Moo;

sub manifest {
  qw(
    T::Foo::Bar::test
    T::Foo::Bar::Condition::is_42
  );
}

1;
