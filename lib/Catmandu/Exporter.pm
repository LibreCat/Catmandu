package Catmandu::Exporter;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(io);
use Moo::Role;

with 'MooX::Log::Any';
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
    }

    package main;

    use Catmandu;

    my $exporter = Catmandu->exporter('Foo', file => "/tmp/output.txt");
    
    # Or on the command line
    $ catmandu convert JSON to Foo < /tmp/something.txt >/tmp/output.txt

=head1 DESCRIPTION

A Catmandu::Exporter is a Perl package the can export data. 
When no options are given exported data is written to
the stdout. Optionally provide a "file" pathname or a "fh" file handle to redirect the
ouput.

Every Catmandu::Exporter is a L<Catmandu::Fixable> and thus provides a "fix" parameter that
can be set in the constructor. For every "add" or for every item in "add_many" the given
fixes will be applied first. E.g.

Every Catmandu::Exporter is a L<Catmandu::Addable> and inherits the methods "add" and "add_many".

=head1 CONFIGURATION

=over

=item file

Write output to a local file given by its path.
Alternatively a scalar reference can be passed to write to a string.

=item fh

Write the output to an IO::Handle. If not specified, Catmandu::Util::io is
used to create the output stream from the "file" argument or by using STDOUT.

=item encoding

Binmode of the output stream "fh". Set to ":utf8" by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied  to exported items.

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

L<Catmandu::Addable>, L<Catmandu::Fix>,L<Catmandu::JSON>,
L<Catmandu::YAML>, L<Catmandu::CSV>, L<Catmandu::RIS>

=cut

1;
