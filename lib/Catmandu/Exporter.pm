package Catmandu::Exporter;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Catmandu::Util qw(io);
use Moo::Role;
use namespace::clean;

with 'Catmandu::Logger';
with 'Catmandu::Addable';
with 'Catmandu::Counter';

has file => (is => 'ro', lazy => 1, default => sub {\*STDOUT},);

has fh => (
    is      => 'ro',
    lazy    => 1,
    default => sub {io($_[0]->file, mode => 'w', binmode => $_[0]->encoding)},
);

after add => sub {
    $_[0]->inc_count;
};

sub encoding {':utf8'}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter - Namespace for packages that can export

=head1 SYNOPSIS

    # From the command line

    # JSON is an importer and YAML an exporter
    $ catmandu convert JSON to YAML < data.json

    # OAI is an importer and JSON an exporter
    $ catmandu convert OAI --url http://biblio.ugent.be/oai to JSON

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('JSON', file => 'data.json');
    my $exporter = Catmandu->exporter('YAML');

    $exporter->add({ record => "one"});
    $exporter->add_many([ { record => "one" } , { record => "two" } ]);
    $exporter->add_many($importer);

    $exporter->commit;

    undef($exporter); # Clean up memory

=head1 DESCRIPTION

A Catmandu::Exporter is a Perl package that can export data into JSON, YAML, XML
or many other formats. By default, data is to STDOUT. Optionally provide a C<file>
or C<fh> parameter to write to a file, string, or handle.

Every Catmandu::Exporter is a L<Catmandu::Fixable> thus provides a C<fix>
parameter and method to apply fixes to exported items:

    my $exporter = Catmandu->exporter('JSON', fix => ['upcase(title)']);

    # This will be printed to STDOUT like: {"title":"MY TITLE"}
    $exporter->add({ title => "my title"});

Every Catmandu::Exporter is a L<Catmandu::Addable> thus inherits the methods
C<add> and C<add_many>.

=head1 CONFIGURATION

=over

=item file

Write output to a local file given by its path or file handle.  Alternatively a
scalar reference can be passed to write to a string and a code reference can be
used to write to a callback function.

=item fh

Write the output to an L<IO::Handle>. If not specified,
L<Catmandu::Util::io|Catmandu::Util/IO-functions> is used to create the output
handle from the C<file> argument or by using STDOUT.

It is the task of the Perl programmer to close any opened IO::Handles.
Catmandu will not do this by itself.

=item encoding

Binmode of the output stream C<fh>. Set to "C<:utf8>" by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to exported items.

=back

=head1 METHODS

=head2 add

Adds one object to be exported.

=head2 add_many

Adds many objects to be exported. This can be either an ARRAY-ref or
an L<Catmandu::Iterator>. Returns a true value when the export was
successful or undef on error.

=head2 count

Returns the number of items exported by this Catmandu::Exporter.

=head2 log

Returns the current logger.

=head2 commit

Commit all buffers to the output handle.

=head1 CODING

Create your own exporter by creating a Perl package in the Catmandu::Exporter namespace
that implements C<Catmandu::Exporter>. Basically, you need to create a method add which
writes a Perl hash to a file handle:


    package Catmandu::Exporter::Foo;

    use Catmandu::Sane;
    use Moo;

    with 'Catmandu::Exporter'

    sub add {
        my ($self, $data) = @_;
        my $fh = $self->fh;
        $fh->print( "Hello, World!");
    }

    sub commit {
        my ($self) = @_;
        # this will be called at the end of the record stream
    }

    1;

This exporter can be called from the command line as:

    $ catmandu convert JSON to Foo < data.json

Or, via Perl

    use Catmandu;

    my $exporter = Catmandu->exporter('Foo', file => "/tmp/output.txt");

    $exporter->add({test => 123});

    $exporter->commit;

    undef($exporter);

=head1 SEE ALSO

See function L<export_to_string|Catmandu/export_to_string> in module
L<Catmandu>.

The exporters L<Catmandu::Exporter::JSON>, L<Catmandu::Exporter::YAML>,
L<Catmandu::Exporter::CSV>, and L<Catmandu::Exporter::Text> are included in
Catmandu core.

See L<Catmandu::Importer> for the opposite action.

=cut
