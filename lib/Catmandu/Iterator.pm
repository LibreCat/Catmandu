package Catmandu::Iterator;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Role::Tiny::With;
use namespace::clean;

with 'Catmandu::Iterable';

sub new {
    bless $_[1], $_[0];
}

sub generator {
    goto &{$_[0]};
}

1;

__END__

=pod

=head1 NAME

Catmandu::Iterator - Base class for all Catmandu iterators

=head1 SYNOPSIS

  package My::MockIterator;

  use Moo;
  
  with 'Catmandu::Iterable';

  sub generator {
    sub {
        # Generator some random data
        +{ random => rand };
    }
  } 

  package main;
 
  my $it = My::MockIterator->new;

  my first = $it->first;

  $it->each(sub {
  my $item = shift;

  print $item->{random} , "\n";
  });

  my $it2 = $it->map(sub { shift->{random} * 2 });

=head1 METHODS

=head2 generator

Should return a closure that generates one Perl hash.

=head1 INHERIT

If you provide a generator, then the class will generator all methods from L<Catmandu::Iterable>.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut
