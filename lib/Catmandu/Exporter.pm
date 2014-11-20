package Catmandu::Exporter;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(io);
use Moo::Role;

with 'Catmandu::Logger';
with 'Catmandu::Addable';
with 'Catmandu::Counter';

has file => (
    is      => 'ro',
    lazy    => 1,
    default => sub { \*STDOUT },
);

has fh => (
    is      => 'ro',
    lazy    => 1,
    default => sub { io($_[0]->file, mode => 'w', binmode => $_[0]->encoding) },
);

after add => sub {
    $_[0]->inc_count;
};

sub encoding { ':utf8' }

1;
__END__

=head1 NAME

Catmandu::Exporter - Namespace for packages that can export

=head1 SYNOPSIS

    package Catmandu::Exporter::Foo;

    use Catmandu::Sane;
    use Moo;

    with 'Catmandu::Exporter'

    sub add {
        my ($self, $data) = @_;
        my $fh = $self->fh;
        $fh->print( ... );
    }

    package main;

    use Catmandu;

    my $exporter = Catmandu->exporter('Foo', file => "/tmp/output.txt");
    
    # Or on the command line
    $ catmandu convert JSON to Foo < /tmp/something.txt >/tmp/output.txt

=head1 DESCRIPTION

A Catmandu::Exporter is a Perl package that can export data. By default, data
items are written to STDOUT. Optionally provide a C<file> or C<fh> parameter to
write to a file, string, or handle. New exporter modules are expected to use the 
C<print> method of C<fh>.

Every Catmandu::Exporter is a L<Catmandu::Fixable> thus provides a C<fix>
parameter and method to apply fixes to exported items.

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

=head1 SEE ALSO

See function L<export_to_string|Catmandu/export_to_string> in module
L<Catmandu>.

The exporters L<Catmandu::Exporter::JSON>, L<Catmandu::Exporter::YAML>,
L<Catmandu::Exporter::CSV>, and L<Catmandu::Exporter::RIS> are included in
Catmandu core.

See L<Catmandu::Importer> for the opposite action.

=cut
