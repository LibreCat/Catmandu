package Catmandu::Plugin::SideCar;

use Catmandu::Sane;

our $VERSION = '1.0603';

use Catmandu::Util qw(:is);
use Hash::Merge::Simple 'merge';
use Moo::Role;
use Package::Stash;
use Carp;
use namespace::clean;

has sidecar => (
    is     => 'ro',
    coerce => sub {
        my $store = $_[0];
        if (is_string($store)) {
            Catmandu->store($store);
        }
        elsif (is_hash_ref($store)) {
            my $package = $store->{package};
            my $options = $store->{options} // +{};
            Catmandu->store($package, %$options);
        }
        else {
            $store;
        }
    }
);

has sidecar_bag => (is => 'ro', default => sub {'data'});

sub BUILD {
    my ($self) = @_;

    my $sidecar = $self->sidecar->bag($self->sidecar_bag);

    # Insert a Catmandu::FileStore 'files' method into Catmandu::Store-s
    unless ($self->does('Catmandu::FileStore')) {
        my $stash = Package::Stash->new(ref $self);
        $stash->add_symbol(
            '&files' => sub {
                my ($self, $id) = @_;
                return $sidecar->files($id);
            }
        );
    }
}

around get => sub {
    my ($orig, $self, @args) = @_;

    my $orig_item = $self->$orig(@args);

    my $bag_name     = $self->sidecar_bag;
    my $bag          = $self->sidecar->bag($bag_name);
    my $sidecar_item = $bag ? $bag->get(@args) : {};

    return unless $sidecar_item || $orig_item;

    merge $sidecar_item , $orig_item // +{};
};

around add => sub {
    my ($orig, $self, @args) = @_;

    my $orig_item = $self->$orig(@args);

    my $bag_name     = $self->sidecar_bag;
    my $bag          = $self->sidecar->bag($bag_name);
    my $sidecar_item = $bag ? $bag->add(@args) : {};

    return unless $sidecar_item || $orig_item;

    merge $sidecar_item , $orig_item // +{};
};

around delete => sub {
    my ($orig, $self, @args) = @_;

    $self->$orig(@args);

    my $bag_name = $self->sidecar_bag;
    my $bag      = $self->sidecar->bag($bag_name);

    $bag->delete(@args) if $bag;
};

around delete_all => sub {
    my ($orig, $self, @args) = @_;

    $self->$orig(@args);

    my $result   = {};
    my $bag_name = $self->sidecar_bag;
    my $bag      = $self->sidecar->bag($bag_name);

    $bag->delete_all(@args) if $bag;
};

around drop => sub {
    my ($orig, $self, @args) = @_;

    $self->$orig(@args);

    my $result   = {};
    my $bag_name = $self->sidecar_bag;
    my $bag      = $self->sidecar->bag($bag_name);

    $bag->drop(@args) if $bag;
};

around commit => sub {
    my ($orig, $self, @args) = @_;

    $self->$orig(@args);

    my $result   = {};
    my $bag_name = $self->sidecar_bag;
    my $bag      = $self->sidecar->bag($bag_name);

    $bag->commit(@args) if $bag;
};

1;

__END__

=pod

=head1 NAME

Catmandu::Plugin::SideCar - Automatically update a parallel Catmandu::Store with metadata

=head1 SYNOPSIS

 # Using the command line

 $ cat catmandu.yml
 ---
 store:
     files:
      package: File::Simple
      options:
          root: /data/test123
          bags:
              index:
                  plugins:
                      - SideCar
                  sidecar:
                          package: ElasticSearch
                          options:
                              client: '1_0::Direct'
                              index_name: catmandu

    ...

 # Add files to the FileStore in bag 1234
 $ catmandu stream /tmp/test.txt to files --bag 1234 --id test.txt

 # Add metadata to the FileStore for bag 1234
 $ cat metadata.yml
 ---
 _id: 1234
 colors:
    - red
    - green
    - blue
 name: test
 ...
 $ catmandu import YAML to files < metadata.yml

 # Export the metadata again from the FileStore
 $ catmandu export files to YAML
 ---
 _id: 1234
 colors:
    - red
    - green
    - blue
 name: test
 ...

 # Or in your Perl program
 my $store = Catmandu->store('File::Simple',
            root => 'data/test123'
            bags => {
                index => {
                    plugins => [qw(SideCar)],
                    sidecar => {
                        package => "ElasticSearch",
                        options => {
                            client => '1_0::Direct',
                            index_name => 'catmandu',
                        }
                    }
               }
            });

 my $index = $store->index;

 $index->add({ _id => '1234' , colors => [qw(red green blue)] , name => 'test'});

 my $files = $index->files('1234');
 $files->upload(IO::File->new('</tmp/test.txt'), 'test.txt');

 my $file = $files->get('text.txt');

 $files->steam(IO::File->new('>/tmp/test.txt'),$file);

=head1 DESCRIPTION

The Catmandu::Plugin::SideCar can be used to combine L<Catmandu::Store>-s , L<Catmandu::FileStore>-s
(and L<Catmandu::Store::Multi> , L<Catmandu::Store::File::Multi>) as one access point.
Every get,add,delete,drop and commit action in the store will be first executed in the original
store and re-executed in the SideCar store.

=head1 COMBINING A FILESTORE WITH A STORE

To add metadata to a L<Catmandu::FileStore> a SideCar needs to be added to the C<index>
bag of the FileStore:

    package: File::Simple
    options:
        root: /data/test123
        bags:
            index:
                plugins:
                    - SideCar
                sidecar:
                        package: ElasticSearch
                        options:
                            client: '1_0::Direct'
                            index_name: catmandu
                sidecar_bag: data

=head1 COMBINING A STORE WITH A FILESTORE

To add files to a L<Catmandu::Store> a SideCar needs to be added to the bag containing
the metadata (by default C<data>):

    package: ElasticSearch
    options:
        client: '1_0::Direct'
        index_name: catmandu
        bags:
            data:
                plugins:
                    - SideCar
                sidecar:
                        package: File::Simple
                        options:
                            root: /data/test123
                            uuid: 1
                sidecar_bag: index

Notice that we added for the L<Catmandu::Store::File::Simple> the requires C<uuid> options
because the L<Catmandu::Store::ElasticSearch> is using UUIDs as default identifiers.

=head1 RESTRICTIONS

Some L<Catmandu::FileStore>-s may set restrictions on the C<_id>-s that can be
used in records.

=head1 CONFIGURATION

=over

=item sidecar STRING

=item sidecar HASH

=item sidecar Catmandu::Store | Catmandu::FileStore

The pointer to a configured Catmandu::Store or Catmandu::FileStore.

=item sidecar_bag

The SideCar L<Catmandu::Bag> into which to store the data (default 'bag').

=back

=head1 SEE ALSO

L<Catmandu::Store>, L<Catmandu::Bag>,
L<Catmandu::FileStore>

=cut
