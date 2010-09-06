package Catmandu::Store;

sub connect {
  bless {}, shift;
}

sub load {
  my ($self,$id) = @_;
  return {};
}

sub save {
  my ($self,$ref) = @_;
  return {};
}

sub purge {
  my ($self,$ref) = @_;
  return 1;
}

sub list {
  my ($self) = @_;
  return [];
}

sub disconnect {
  return 1;
}

1;

__END__

=head1 NAME

 Catmandu::Store - An storage interface for Perl data structures

=head1 SYNOPSIS

 use Catmandu::Store;

 my $store = Catmandu::Store->connect();
 my $obj = { name => 'Catmandu' , age => 1 };
 
 my $obj = $store->save($obj); # $obj = { _id => '1271-23138230-AEF12781' , name => 'Catmandu' , age => 1 };

 my $obj = $store->load('1271-23138230-AEF12781');

 $store->purge($obj);

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

=item connect(opt1=>val1, opt2=>val2, ..)

Connect to a Catmandu::Store using the connection variables passed as a perl HASH. Returns
a true value on success, undef on failure.

=item load($id)

Retrieve a Perl object from the store given an identifier. Returns the object as perl HASH on
success, return undef on failure.

=item save($obj);

Save a Perl object into the store. Returns the saved object on success or undef on failure.

=item purge($obj);

Purges the Perl object from the store. Returns a true value on sucess, undef on failure.

=item list;

Returns a list of all Perl objects in the store.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
