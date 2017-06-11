package Catmandu::Plugin::SideCar;

use Catmandu::Sane;

our $VERSION = '1.0507';

use Catmandu::Util qw(:is);
use Hash::Merge::Simple 'merge';
use Moo::Role;
use Carp;
use namespace::clean;

has sidecar => (
    is      => 'ro',
    coerce  => sub {
        my $store = $_[0];
        if (is_string($store)) {
            Catmandu->store($store);
        }
        elsif (is_hash_ref($store)) {
            my $package = $store->{package};
            my $options = $store->{options} // +{};
            Catmandu->store($package,%$options);
        }
        else {
            $store;
        }
    }
);

has sidecar_bag => (is => 'ro' , default => sub { 'data' });

around get => sub {
    my ( $orig, $self, @args ) = @_;

    my $result = {};
    my $bag_name = $self->sidecar_bag;
    my $bag      = $self->sidecar->bag($bag_name);
    my $metadata_item = $bag ? $bag->get(@args) : {};

    my $file_item = $self->$orig(@args);

    return unless $metadata_item || $file_item;

    merge $metadata_item , $file_item // +{};
};

around add => sub {
    my ( $orig, $self, @args ) = @_;

    my $result = {};
    my $bag_name = $self->sidecar_bag;
    my $bag      = $self->sidecar->bag($bag_name);
    my $metadata_item = $bag ? $bag->add(@args) : {};

    my $file_item = $self->$orig(@args);

    return unless $metadata_item || $file_item;

    merge $metadata_item , $file_item // +{};
};

around delete => sub {
    my ( $orig, $self, @args ) = @_;

    my $result = {};
    my $bag_name = $self->sidecar_bag;
    my $bag      = $self->sidecar->bag($bag_name);
    my $metadata_item = $bag ? $bag->delete(@args) : {};

    $self->$orig(@args);
};

around delete_all => sub {
    my ( $orig, $self, @args ) = @_;

    my $result = {};
    my $bag_name = $self->sidecar_bag;
    my $bag      = $self->sidecar->bag($bag_name);
    my $metadata_item = $bag ? $bag->delete_all(@args) : {};

    $self->$orig(@args);
};

around drop => sub {
    my ( $orig, $self, @args ) = @_;

    my $result = {};
    my $bag_name = $self->sidecar_bag;
    my $bag      = $self->sidecar->bag($bag_name);
    my $metadata_item = $bag ? $bag->drop(@args) : {};

    $self->$orig(@args);
};

around commit => sub {
    my ( $orig, $self, @args ) = @_;

    my $result = {};
    my $bag_name = $self->sidecar_bag;
    my $bag      = $self->sidecar->bag($bag_name);
    my $metadata_item = $bag ? $bag->commit(@args) : {};

    $self->$orig(@args);
};

sub stream {
    my ($self,$id,$io,$name) = @_;

    croak "usage: upload(id,IO::File,name)" unless defined($id) && defined($io) && defined($name);

    my @file_stores;

    if ($self->does('Catmandu::FileStore')) {
        push @file_stores , $self;
    }

    if ($self->sidecar->does('Catmandu::FileStore')) {
        push @file_stores , $self->sidecar;
    }

    unless (@file_stores) {
        Catmandu::Error->throw($self->sidecar . " isn't a Catmandu::FileStore");
    }

    my $store = pop @file_stores;

    my $file = $store->bag($id)->get($name);

    return undef unless $file;

    $store->bag($id)->stream($io,$file);
}

sub upload {
    my ($self,$id,$io,$name) = @_;

    croak "usage: upload(id,IO::File,name)" unless defined($id) && defined($io) && defined($name);

    my @file_stores;

    if ($self->does('Catmandu::FileStore')) {
        push @file_stores , $self;
    }

    if ($self->sidecar->does('Catmandu::FileStore')) {
        push @file_stores , $self->sidecar;
    }

    unless (@file_stores) {
        Catmandu::Error->throw($self->sidecar . " isn't a Catmandu::FileStore");
    }

    my $rewind;

    for my $store (@file_stores) {
        if ($rewind) {
            # Rewind the stream after first use...
            Catmandu::BadVal->throw("IO stream needs to seekable") unless $io->isa('IO::Seekable');
            $io->seek(0,0);
        }

        my $index = $store->index;

        $index->add({ _id => $id}) unless $index->exists($id);

        my $container = $store->bag($id);

        $container->upload($io,$name);

        $rewind = 1;
    }

    1;
}

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
      package: Simple
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
 my $store = Catmandu->store('Simple',
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

 $store->bag('1234')->upload(IO::File->new('</tmp/test.txt'), 'test.txt');

=head1 DESCRIPTION

The Catmandu::Plugin::SideCar can be used to combine L<Catmandu::Store>-s , L<Catmandu::FileStore>-s
(and L<Catmandu::Store::Multi> , L<Catmandu::Store::MultiFiles> as one access point.
Every get,add,delete,drop and commit action in the store will be first executed in the original
store and re-executed in the SideCar store.

=head1 CONFIGURATION

=over

=item sidecar STRING

=item sidecar HASH

=item sidecar Catmandu::Store | Catmandu::FileStore

The pointer to a configured Catmandu::Store or Catmandu::FileStore.

=item sidecar_bag

The SideCar L<Catmandu::Bag> into which to store the data (default 'bag').

=back

=head1 METHODS

=over

=item upload($id, IO::File, $name)

Upload an IO::File for record $id with filename $name in case the original store or the SideCar is a
L<Catmandu::File::Store>

=item stream($id, IO::File, $name)

Stream for record $id the contents of $name to the IO::File handle.

=head1 SEE ALSO

L<Catmandu::Store>, L<Catmandu::Bag>,
L<Catmandu::FileStore>

=cut
