package Catmandu::Store::Mock;

use 5.010;
use strict;
use warnings;
use Storable;
use Data::UUID;

sub connect {
  my ($pkg,%opts) = @_;
  die "usage: Catmandu::Store::Mock->connect(file => '...')" unless ($opts{file});
  unless (-r $opts{file}) {
    Storable::nstore({},$opts{file});
  }
  bless {
     file => $opts{file}
  } , $pkg;
}

sub load {
  my ($self,$id) = @_;

  my $hashref = Storable::retrieve($self->{file});

  $hashref->{$id};
}

sub save {
  my ($self,$ref) = @_;
  my $id = Data::UUID->new->create_str();
  my $hashref = Storable::retrieve($self->{file});

  $ref->{_id}     = $id;
  $hashref->{$id} = $ref;

  Storable::nstore($hashref, $self->{file});

  $ref;
}

sub delete {
  my ($self,$ref) = @_;
  my $id = $ref->{_id};
  my $hashref = Storable::retrieve($self->{file});

  if (exists $hashref->{$id}) {
    delete $hashref->{$id};
    Storable::nstore($hashref, $self->{file});
    1;
  }
  else {
    0;
  }
}

sub each {
  my ($self,$block) = @_;
  my $hashref = Storable::retrieve($self->{file});

  my $count = 0;
  while ( my ($key, $object) = each(%$hashref) ) {
    &$block($object) if defined $block;
    $count++;
  }

  $count;
}

sub disconnect {
  1;
}

1;

__END__

=head1 NAME

 Catmandu::Store::Mock - An storage interface for Perl data structures

=head1 SYNOPSIS

 use Catmandu::Store::Mock;

 my $store = Catmandu::Store::Mock->connect(file => '/tmp/mock.db');
 my $obj = { name => 'Catmandu' , age => 1 };
 
 my $obj = $store->save($obj); # $obj = { _id => '1271-23138230-AEF12781' , name => 'Catmandu' , age => 1 };

 my $obj = $store->load('1271-23138230-AEF12781');

 $store->delete($obj);

 foreach my $obj ($store->list) {
    printf "%s\n" , $obj->{name};
 } 

 $store->disconnect;

=head1 DESCRIPTION

Catmandu::Store is an abstract interface to be used as template for defining Perl object storage
and retrieval modules. An Catmandu::Store is a Perl module that implements all the methods of
Catmandu::Store.

=head1 METHODS

=over 4

=item connect(file => '/tmp/mock.t')

Connect to a Catmandu::Store using the connection variables passed as a perl HASH. Returns
a true value on success, undef on failure.

=item load($id)

Retrieve a Perl object from the store given an identifier. Returns the object as perl HASH on
success, return undef on failure.

=item save($obj);

Save a Perl object into the store. Returns the saved object on success or undef on failure.

=item delete($obj);

Delete the Perl object from the store. Returns a true value on sucess, undef on failure.

=item each(BLOCK);

For every Perl object in the store run the BLOCK code. The BLOCK gets the current Perl object
as first argument. Returns the number of Perl objects found.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
