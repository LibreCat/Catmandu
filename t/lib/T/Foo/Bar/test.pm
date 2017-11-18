package T::Foo::Bar::test;
use Moo;

sub fix {
  my ($self,$data) = @_;

  $data->{test} = 'ok';

  $data;
}

1;
