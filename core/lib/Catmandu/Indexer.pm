package Catmandu::Indexer;

use Mouse;

has 'driver' => (is => 'ro' , required => 1, handles => [qw(each done)]);

sub BUILDARGS {
    my ($pkg, $driver_pkg, @args) = @_;

    $driver_pkg or confess "Driver is required";
    if ($driver_pkg !~ /::/) {
        $driver_pkg = "$pkg::$driver_pkg";
    }
    eval { Mouse::Util::load_class($driver_pkg) } or
        confess "Can't load driver $driver_pkg";

    return {
        driver => $driver_pkg->new(@args),
    };
}

sub DEMOLISH {
    $_[0]->done;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

 Catmandu::Indexer - An indexer for Perl bibliographic data structures.

=head1 SYNOPSIS

 my $indexer = Catmandu::Indexer->new('SOLR', host => ... , port => ... , ...);

 $indexer->delete(id => 1192121);
 $indexer->delete(type => 'article');

 my $store   = Catmandu::Store->new('CouchDB', ...);
 my $obj  = $store->load('2393823101238');

 # Index single object using a standard converter
 $indexer->index($obj);

 # Index single object using a subroutine that can flatten 
 # the Perl bibliographic data structure
 $indexer->index($obj, sub {
    my $obj = shift;
    flatten $obj;
 });

 # Index single object using an object that implements a 'convert' method
 $indexer->index($obj, Catmandu::Indexer::Converter->new('UGent'));

 # Index an array of objects...all above conversion options apply also here
 $indexer->index([$obj1 $obj2 ...$objN);

 # Index a stream of objects...all above conversion options apply also here
 $indexer->index(Catmandu::Importer->new('JSON', ...)); 

 $indexer->done;

=head1 METHODS

=over 4

=item new($driver_pkg, @args)

Constructs a new indexer. Passes @args to the driver instance.
C<$driver_pkg> is assumed to live in the Catmandu::Indexer 
namespace unless a full package name is given. 

=item delete(%condition)

Delete a document from the index. The condition contains one or more index fields
to search.

=item index($hash_ref [,$converter])

=item index($array_ref [,$converter])

=item index($something_that_can_do_each [,$converter])

Indexes C<$obj>. C<$obj> can be a hashref, arrayref or an object 
with an C<each> method. Optionally a C<$converter> can be provided
that should flatten Perl bibliographic hashrefs into indexable fields.
This  C<$converter> can be a subroutine or a Perl object that 
implements C<convert>.

=item done()

Explicitly teardown the driver. This method is called at 
C<DESTROY> time. Returns 1 or 0.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
