package Catmandu::Store;

use Moose::Role;

requires 'load';
requires 'each';
requires 'save';
requires 'delete';

no Moose::Role;
__PACKAGE__;

__END__

=head1 NAME

Catmandu::Store - role describing a store.

=head1 SYNOPSIS

    # loading an object from the store:
    $store->load("9BC2FC08-EE3B-11DF-BF4D-7B7478AD8B0A");
    # ==> { _id => "9BC2FC08-EE3B-11DF-BF4D-7B7478AD8B0A", title => "Island" }

    # iterating over the store:
    my $count = $store->each(sub { my $obj = shift; say $obj->{title}; });

    # inserting an object:
    $store->save({ title => "1984", authors => ['Aldous Huxley']});
    # ==> { _id => "D5665B90-EE3A-11DF-BF4D-7B7478AD8B0A", title => "1984", authors => ['Aldous Huxley']}

    # updating an existing object:
    $store->save({ _id => "D5665B90-EE3A-11DF-BF4D-7B7478AD8B0A", title => "1984", authors => ['George Orwell']});

    # deleting an object:
    $store->delete("D5665B90-EE3A-11DF-BF4D-7B7478AD8B0A");
    # or:
    $store->delete({ _id => "D5665B90-EE3A-11DF-BF4D-7B7478AD8B0A"});

=head1 DESCRIPTION

A class using L<Catmandu::Store> can store complex (bibliographic) objects,
represented as a hashref and uniquely identified by their _id key.

=head1 METHODS

=head2 $c->load($id)

Retrieve the object with _id C<$id> form the store. Returns
the object as a hashref when found, C<undef> otherwise.

=head2 $c->each($sub)

Iterates over all objects in the store and passes them to C<$sub>.
Returns the number of objects found.

=head2 $c->save($obj)

Inserts or updates C<$obj> in the store. Returns the object as a hashref
when found, C<undef> otherwise.

=head2 $c->delete($obj or $id)

Delete C<$obj> or object with _id C<$id> from the store.

=head1 SEE ALSO

L<Catmandu::Store::Simple>, an included Store implementation that uses DBD::SQlite as storage layer.

