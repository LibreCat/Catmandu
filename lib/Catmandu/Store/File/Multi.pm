package Catmandu::Store::File::Multi;

use Catmandu::Sane;

our $VERSION = '1.06';

use Catmandu::Util qw(:is);
use Hash::Util::FieldHash qw(fieldhash);
use Catmandu::Store::Multi::Bag;
use Moo;
use namespace::clean;

with 'Catmandu::FileStore';

has stores => (
    is       => 'ro',
    required => 1,
    default  => sub {[]},
    coerce   => sub {
        my $stores = $_[0];
        return [
            map {
                if (is_string($_)) {
                    Catmandu->store($_);
                }
                else {
                    $_;
                }
            } @$stores
        ];
    },
);

sub drop {
    my ($self) = @_;

    for my $store (@{$self->stores}) {
        $store->drop if $store->does('Catmandu::Droppable');
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::Multi - A store that adds files to multiple stores

=head1 SYNOPSIS

    # On the Command line

    # Configure the File::Multi store with a catmandu.yml file
    $ cat catmandu.yml
    ---
    store:
      files1:
       package: File::Simple
       options:
          root: /data1/files
      files1:
       package: File::Simple
       options:
          root: /data1/files_copy
      multi:
       package: File::Multi
       options:
           stores:
               - files1
               - files2
    ...

    # List all the folder in the multi store as YAML
    $ catmandu export multi to YAML

    # Add a file to the multi store with ID 7890 and stored name data.dat
    $ catmandu stream /tmp/data.dat to multi --bag 7890 --id data.dat

    # Download a file from the multi store
    $ catmandu stream multi --bag 7890 --id data.dat

    # In Perl
    use Catmandu;

    my $store = Catmandu->store('File::Multi' , stores [
        Catmandu->store('Simple', root => '/data1/files') ,
        Catmandu->store('Simple', root => '/data1/files_copy') ,
    ]);

    my $index = $store->index;

    $store->index->each(sub {
        my $item = shift;
        printf "%s\n" , $item->{_id};
    });

    # Add a folder to the multi store
    my $item = $store->add({ _id => '1234');

    # Retrieve the folder bag
    my $files = $store->files(1234);

    # Listing of all files
    $files->each(sub {
        my $file = shift;

        my $name         = $file->_id;
        my $size         = $file->size;
        my $content_type = $file->content_type;
        my $created      = $file->created;
        my $modified     = $file->modified;

        $file->stream(IO::File->new(">/tmp/$name"), file);
    });

    # Add a new file
    $files->upload(IO::File->new("</tmp/data.dat"),"data.dat");

    # Retrieve a file
    my $file = $files->get('data.dat');

    # Stream the file to an IO::Handle
    $container->stream(IO::File->new(">/tmp/data.dat"),$file);

    # This will delete the folder and files
    $index->delete('1234');

=head1 DESCRIPTION

The L<Catmandu::Store::File::Multi> is a combination of many L<Catmandu::FileStore>-s
as one access point. The Multi store inherits all the methods
from L<Catmandu::FileStore>.

By default, the Multi store tries to update records in all configured backend
stores. Importing, exporting, delete and drop will be executed against
all backend stores when possible.

=head1 CONFIGURATION

=head2 stores ARRAY(string)

=head2 stores ARRAY(Catmandu::FileStore)

The C<store> configuration parameter contains an array of references to
L<Catmandu::FileStore>-s based on their name in a configuration file or instances.

=head1 SEE ALSO

L<Catmandu::Store::File::Multi::Index> ,
L<Catmandu::Store::File::Multi::Bag> ,
L<Catmandu::FileStore> ,
L<Catmandu::Plugin::SideCar>
L<Catmandu::Store> ,
L<Catmandu::Bag>

=cut
