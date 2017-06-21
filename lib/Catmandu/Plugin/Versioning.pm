package Catmandu::Plugin::Versioning;

use Catmandu::Sane;

our $VERSION = '1.06';

use Catmandu::Util qw(is_value is_array_ref check_value check_positive);
use Data::Compare;
use Moo::Role;
use MooX::Aliases;
use namespace::clean;

has version_bag_name => (is => 'lazy', init_arg => 'version_bag');
has version_bag      => (is => 'lazy', init_arg => undef);
has version_key      => (is => 'lazy', alias    => 'version_field');

has version_compare_ignore => (
    is     => 'lazy',
    coerce => sub {
        my $keys = $_[0];
        $keys = [@$keys] if is_array_ref $keys;
        $keys = [split /,/, $keys] if is_value $keys;
        $keys;
    },
);

has version_transfer => (
    is     => 'lazy',
    coerce => sub {
        my $keys = $_[0];
        $keys = [@$keys] if is_array_ref $keys;
        $keys = [split /,/, $keys] if is_value $keys;
        $keys;
    },
);

sub _build_version_bag_name {
    $_[0]->name . '_version';
}

sub _build_version_bag {
    $_[0]->store->bag($_[0]->version_bag_name);
}

sub _build_version_key {
    $_[0]->store->key_for('version');
}

sub _build_version_compare_ignore {
    [$_[0]->version_key];
}

sub _trigger_version_compare_ignore {
    my ($self, $keys) = @_;
    my $version_key = $self->version_key;
    push @$keys, $version_key unless grep /^$version_key$/, @$keys;
}

sub _build_version_transfer {
    [];
}

sub _version_id {
    my ($self, $id, $version) = @_;
    "$id.$version";
}

around add => sub {
    my ($sub, $self, $data) = @_;
    my $id_key      = $self->id_key;
    my $version_key = $self->version_key;
    if (defined $data->{$id_key} and my $d = $self->get($data->{$id_key})) {
        $data->{$version_key} = $d->{$version_key} ||= 1;
        for my $key (@{$self->version_transfer}) {
            next if exists $data->{$key} || !exists $d->{$key};
            $data->{$key} = $d->{$key};
        }
        return $data
            if Compare($data, $d,
            {ignore_hash_keys => $self->version_compare_ignore});
        my $version_id
            = $self->_version_id($data->{$id_key}, $data->{$version_key});
        $self->version_bag->add(
            {$self->version_bag->id_key => $version_id, data => $d});
        $data->{$version_key}++;
    }
    else {
        $data->{$version_key} ||= 1;
    }
    $sub->($self, $data);
};

sub get_history {
    my ($self, $id, %opts) = @_;
    if (my $data = $self->get($id)) {
        my $history = [$data];
        my $version = $data->{$self->version_key} || 1;
        while (--$version) {
            push @$history, $self->get_version($id, $version);
        }
        return $history;
    }
    return;
}

sub get_version {
    my ($self, $id, $version) = @_;
    check_value($id);
    check_positive($version);
    my $data;
    my $version_id = $self->_version_id($id, $version);
    if ($data = $self->version_bag->get($version_id)) {
        return $data->{data};
    }
    if ($data = $self->get($id) and $data->{$self->version_key} == $version) {
        return $data;
    }
    return;
}

sub restore_version {
    my ($self, $id, $version) = @_;
    if (my $data = $self->get_version($id, $version)) {
        return $self->add($data);
    }
    return;
}

sub get_previous_version {
    my ($self, $id) = @_;
    if (my $data = $self->get($id)) {
        my $version = $data->{$self->version_key} || 1;
        if ($version > 1) {
            return $self->get_version($id, $version - 1);
        }
    }
    return;
}

sub restore_previous_version {
    my ($self, $id) = @_;
    if (my $data = $self->get_previous_version($id)) {
        return $self->add($data);
    }
    return;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Plugin::Versioning - Automatically adds versioning to Catmandu::Store records

=head1 SYNOPSIS

 # Using configuration files

 $ cat catmandu.yml
 ---
 store:
  test:
    package: MongoDB
    options:
      database_name: test
      bags:
        data:
          plugins:
            - Versioning

 # Add two version of record 001 to the store
 $ echo '{"_id":"001",hello":"world"}' | catmandu import JSON to test
 $ echo '{"_id":"001",hello":"world2"}' | catmandu import JSON to test

 # In the store we see only the latest version
 $ catmandu export test to YAML
 ---
 _id: '001'
 _version: 2
 hello: world2

 # In the '_version' store we'll find all the previous versions
 $ catmandu export test --bag data_version to YAML
 ---
 _id: '001.1'
 data:
  _id: '001'
  _version: 1
  hello: world

 # Or in your Perl program
 my $store = Catmandu->store('MongoDB',
            database_name => 'test' ,
            bags => {
                data => {
                plugins => [qw(Versioning)]
            }
        });

 $store->bag->add({ _id => '001' , hello => 'world'});
 $store->bag->add({ _id => '001' , hello => 'world2'});

 print "Versions:\n";

 for (@{$store->bag->get_history('001')}) {
    print Dumper($_);
 }

=head1 DESCRIPTION

The Catmandu::Plugin::Versioning plugin automatically adds a new 'version' bag to your Catmandu::Store
containing previous versions of newly created records. The name of the version is created by appending
'_version' to your original bag name. E.g. when add the Versioning plugin to a 'test' bag then 'test_version'
will contain the previous version of all your records.

When using Catmandu::Store-s that don't have dynamic schema's (e.g. Solr , DBI) these new bags need to be
predefined (e.g. create new Solr cores or database tables).

=head1 CONFIGURATION

=over

=item version_compare_ignore

By default every change to a record with trigger the creation of a new version. Use the version_compare_ignore option
to specify fields that should be ignored when testing for new updates. E.g. in the example below we configured the
MongoDB store to add versioning to the default 'data' bag. We want to ignore changes to the 'date_updated' field
when creating new version records

 # catmandu.yml
 ---
 store:
  test:
    package: MongoDB
    options:
      database_name: test
      bags:
        data:
          plugins:
            - Versioning
          version_compare_ignore:
            - date_updated

 # In your perl

 # First version
 $store->bag->add({ _id => '001' , name => 'test' , date_updated => '10:00' });

 # Second version (name has changed)
 $store->bag->add({ _id => '001' , name => 'test123' , date_updated => '10:00' });

 # Second version (date_updated has changed but we ignored that in our configuration)
 $store->bag->add({ _id => '001' , name => 'test123' , date_updated => '10:15' });

=item version_transfer

This option autmatically copies the configured fields from the previous version of a record to the new version of the
record. E.g. in the example below we will create a versioning on the default bag and add a rights statement that can
not be deleted.

 # catmandu.yml
 ---
 store:
  test:
    package: MongoDB
    options:
      database_name: test
      bags:
        data:
          plugins:
            - Versioning
          version_transfer:
            - rights:

 # In your perl

 # First version
 $store->bag->add({ _id => '001' , name => 'test' , rights => 'Acme Corp.' });

 # Second version we will try you delete rights but this is copied to the new version
 $store->bag->add({ _id => '001' , name => 'test'});

 print "Rights: %s\n" , $store->bag->get('001')->{rights}; # Rights: Acme Corp.

=item version_bag

The name of the bag that stores the versions. Default is the name of the
versioned bag with '_version' appended.

    my $store = Catmandu::Store::MyDB->new(bags => {book => {plugins =>
        ['Versioning'], version_bag => 'book_history'}});
    $store->bag('book')->version_bag->name # returns 'book_history'

=item version_key

Use a custom key to hold the version number in this bag. Default is '_version'
unless the store has a custom C<key_prefix>. Also aliased as C<version_field>.

=back

=head1 METHODS

Every bag that is configured with the Catmandu::Plugin::Versioning plugin can use the following methods:

=head2 get_version(ID,VERSION)

Retrieve a record with identifier ID and version identifier VERSION. E.g.

    my $obj = $store->bag('test')->get_version('001',1);

=head2 get_previous_version(ID)

Retrieve the previous version of a record with identifier ID. E.g.

=head2 get_history(ID)

Returns an ARRAY reference with all the versions of the record with identifier ID.

=head2 restore_version(ID,VERSION)

Overwrites the current version of the stored record with identifier ID with a version with identifier VERSION.

=head2 restore_previous_version(ID)

Overwrites the current version of the stored record with identifier ID with its previous version.

=head1 SEE ALSO

L<Catmandu::Store>, L<Catmandu::Bag>

=cut
