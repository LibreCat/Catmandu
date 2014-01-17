package Catmandu::Plugin::Versioning;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(is_value check_value check_positive);
use Data::Compare;
use Moo::Role;

has version_bag => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_version_bag'
);

has version_compare_ignore => (
    is      => 'ro',
    lazy    => 1,
    default => sub { [qw(_version)] },
    coerce  => sub {
        my $keys = $_[0];
        $keys = [split /,/, $keys] if is_value $keys;
        push @$keys, '_version';
        $keys;
    },
);

has version_transfer => (
    is      => 'ro',
    lazy    => 1,
    default => sub { [] },
    coerce  => sub {
        my $keys = $_[0];
        $keys = [split /,/, $keys] if is_value $keys;
        $keys;
    },
);

sub _build_version_bag {
    $_[0]->store->bag($_[0]->name . '_version');
}

around add => sub {
    my ($sub, $self, $data) = @_;
    if (defined $data->{_id} and my $d = $self->get($data->{_id})) {
        $data->{_version} = $d->{_version} ||= 1;
        for my $key (@{$self->version_transfer}) {
            next if exists $data->{$key} || !exists $d->{$key};
            $data->{$key} = $d->{$key};
        }
        return $data
            if Compare($data, $d, {ignore_hash_keys => $self->version_compare_ignore});
        $self->version_bag->add({_id => "$data->{_id}.$data->{_version}", data => $d});
        $data->{_version}++;
    } else {
        $data->{_version} ||= 1;
    }
    $sub->($self, $data);
};

sub get_history {
    my ($self, $id, %opts) = @_;
    if (my $data = $self->get($id)) {
        my $history = [$data];
        my $version = $data->{_version} || 1;
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
    my $data = $self->version_bag->get("$id.$version") || return;
    $data->{data};
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
        my $version = $data->{_version} || 1;
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

no Data::Compare;

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
 my $store = Catmandu::Store::MongoDB->new(
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

The Catmandu::Plugin::Versioning plugin automatically adds a new 'version' bag to your Catmandy::Store
containing previous versions of newly created records. The name of the version is created by appending 
'_version' to your original bag name. E.g. when add the Versioning plugin to a 'test' bag then 'test_version'
will contain the previous version of all your records.

When using Catmandu::Store-s that don't have dynamic schema's (e.g. Solr , DBI) these new bags need to be
predefined (e.g. create new Solr cores or database tables).

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

=head1 OPTIONS

=head2 version_compare_ignore

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

=head2 version_transfer

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

=head1 SEE ALSO

L<Catmandu::Store>, L<Catmandu::Bag>

=cut

1;
