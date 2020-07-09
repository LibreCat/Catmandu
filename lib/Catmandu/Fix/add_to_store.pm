package Catmandu::Fix::add_to_store;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu;
use Catmandu::Util::Path qw(as_path);
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path       => (fix_arg => 1);
has store_name => (fix_arg => 1);
has bag_name   => (fix_opt => 1, init_arg => 'bag');
has store_args => (fix_opt => 'collect');
has store      => (is      => 'lazy', init_arg => undef);
has bag        => (is      => 'lazy', init_arg => undef);

with 'Catmandu::Fix::Builder';

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
    my $bag    = $self->bag;
    my $getter = as_path($self->path)->getter;
    sub {
        my $data = $_[0];
        my $vals = $getter->($data);
        $bag->add($_) for @$vals;
        $data;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::add_to_store - add matching values to a store as a side effect

=head1 SYNOPSIS

   # Add the current record to an SQLite database.
   add_to_store(., DBI, data_source: "dbi:SQLite:path/data.sqlite")

   # Add the journal field to a MongoDB database.
   add_to_store(journal, MongoDB, database_name: catalog)

   # Add all author values to a MongoDB database.
   add_to_store(authors.*, MongoDB, database_name: catalog, bag: authors)

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
   #      database_name: catalog
   add_to_store(., mydbi)
   add_to_store(journal, mymongo)
   add_to_store(authors.*, mymongo, bag: authors)

=head1 DESCRIPTION

=head2 add_to_store(PATH,STORE[,store_param: store_val, ...][,bag: bag_name])

Store a record or parts of a record in a Catmandu::Store.
The values at the PATH will be stored as-is in the database but should be hashes.
If the value contains an '_id' field, then it will
used as record identifier in the database. If not, then a new '_id' field will
be generated and added to the database and original field (for later reference).

For instance this YAML input:

    ---
    _id: 001
    title: test
    name: foo
    ---
    _id: 002
    title: test2
    name: bar

with the fix:

    add_to_store(., DBI, data_source: "dbi:SQLite:path/data.sqlite")

will create a path/data.sqlite SQLite database with two records. Each records contains
the _id from the input file and all the record fields.

For instance this YAML input:

    ---
    title: test
    name: foo
    ---
    title: test2
    name: bar

with the fix:

    add_to_store(., DBI, data_source: "dbi:SQLite:path/data.sqlite")

will create a path/data.sqlite SQLite database with two records. Each records contains
the a generated _id and all the record fields. The current input stream will be updated
to contain the generated _id.

Use L<Catmandu::Fix::lookup_in_store> to lookup records in a Catmandu::Store based
on an '_id' key.

=head1 DATABASE CONNECTIONS

For every call to a C<add_to_store> a new database connection is created. It
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

L<Catmandu::Fix> , L<Catmandu::Fix::lookup_in_store>

=cut

1;
