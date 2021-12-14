package Catmandu::Fix::lookup_in_store;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Catmandu;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Util qw(is_value);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path       => (fix_arg => 1);
has store_name => (fix_arg => 1);
has bag_name   => (fix_opt => 1, init_arg  => 'bag');
has default    => (fix_opt => 1, predicate => 1);
has delete     => (fix_opt => 1);
has store_args => (fix_opt => 'collect');
has store      => (is      => 'lazy', init_arg => undef);
has bag        => (is      => 'lazy', init_arg => undef);

sub _build_store {
    my ($self) = @_;
    Catmandu->store($self->store_name, %{$self->store_args});
}

sub _build_bag {
    my ($self) = @_;
    defined $self->bag_name
        ? $self->store->bag($self->bag_name)
        : $self->store->bag;
}

sub _build_fixer {
    my ($self) = @_;

    my $bag = $self->bag;
    my $cb;

    if ($self->delete) {
        $cb = sub {
            my $val = $_[0];
            if (is_value($val) && defined($val = $bag->get($val))) {
                return $val;
            }
            return undef, 1, 1;
        };
    }
    elsif ($self->has_default) {
        my $default = $self->default;
        $cb = sub {
            my $val = $_[0];
            if (is_value($val) && defined($val = $bag->get($val))) {
                return $val;
            }
            $default;
        };
    }
    else {
        $cb = sub {
            my $val = $_[0];
            if (is_value($val) && defined($val = $bag->get($val))) {
                return $val;
            }
            return undef, 1, 0;
        };
    }

    as_path($self->path)->updater($cb);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::lookup_in_store - change the value of a HASH key or ARRAY index
by looking up its value in a store

=head1 SYNOPSIS

   # Lookup in an SQLLite database
   lookup_in_store(foo.bar, DBI, data_source: "dbi:SQLite:path/data.sqlite")

   # Lookup in a MongoDB database
   lookup_in_store(foo.bar, MongoDB, database_name: lookups, bag: mydata)

   # Lookup in a MongoDB database, using the default bag and a default value when nothing found
   lookup_in_store(foo.bar, MongoDB, database_name: lookups, default: 'default value')

   # Lookup in a MongoDB database, using the default bag and delete the foo.bar field when nothing found
   lookup_in_store(foo.bar, MongoDB, database_name: lookups, delete: 1)

   # Or, a much faster option: use a named store in a catmandu.yml file
   #
   # store:
   #  mydbi:
   #    package: DBI
   #    options:
   #      data_source: "dbi:SQLite:path/data.sqlite"
   #  mymongo:
   #    package: MongoDB
   #    options:
   #      database_name: lookups
   lookup_in_store(foo.bar, mydbi)
   lookup_in_store(foo.bar, mymongo, bag: mydata)
   lookup_in_store(foo.bar, mymongo, default: 'default value')
   lookup_in_store(foo.bar, mymongo, delete: 1)

=head1 DESCRIPTION

=head2 lookup_in_store(PATH,STORE[,store_param: store_val, ...][,bag: bag_name][,delete:1][,default:value])

Use the lookup_in_store fix to match a field in a record to the "_id" field in
a Catmandu::Store of choice.  For instance, if a Catmandu::Store contains these
records:

    ---
    _id: water
    fr: l'eau
    de: wasser
    en: water
    nl: water
    ---
    _id: tree
    fr: arbre
    de: baum
    en: tree
    nl: boom

And you data contains these fields:

    ---
    _id: 001
    tag: tree
    ---
    _id: 002
    tag: water

Then, the fix below will lookup a tag in the Catmandu::Store and replace it
with the database value:

    lookup_in_store(tag, DBI, data_source: "dbi:SQLite:path/data.sqlite")

The resulting data will contain:

    ---
    _id: 001
    tag:
      _id: tree
      fr: arbre
      de: baum
      en: tree
      nl: boom
    ---
    _id: 002
    tag:
      _id: water
      fr: l'eau
      de: wasser
      en: water
      nl: water

=head1 DATABASE CONNECTIONS

For every call to a C<lookup_in_store> a new database connection is created. It
is much more effient to used named stores in a C<catmandu.yml> file. This file
needs to contain all the connection parameters to the database. E.g.

    store:
       mystore:
         package: MongoDB
         options:
            database_name: mydata

The  C<catmandu.yml> file should be available in the same directory as where the
C<catmandu> command is executed. Or, this directory can be set with the C<-L> option:

    $ catmandu -L /tmp/path convert ...

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Store> , L<Catmandu::Fix::add_to_store>

=cut
