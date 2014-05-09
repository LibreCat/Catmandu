package Catmandu::Importer;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(io);
use Moo::Role;

with 'MooX::Log::Any';
with 'Catmandu::Iterable';
with 'Catmandu::Fixable';

around generator => sub {
    my ($orig, $self) = @_;
    my $generator = $orig->($self);
    if (my $fixer = $self->_fixer) {
        return $fixer->fix($generator);
    }
    $generator;
};

has file => (
    is      => 'ro',
    lazy    => 1,
    default => sub { \*STDIN },
);

has fh => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);

has encoding => (
    is       => 'ro',
    builder  => 1,
);

sub _build_encoding {
    ':utf8';
}

sub _build_fh {
    # build from file. may be build from URL in a future version
    io($_[0]->file, mode => 'r', binmode => $_[0]->encoding);
}

sub readline {
    $_[0]->fh->getline;
}

sub readall {
    join '', $_[0]->fh->getlines;
}

=head1 NAME

Catmandu::Importer - Namespace for packages that can import

=head1 SYNOPSIS

    package Catmandu::Importer::Hello;

    use Catmandu::Sane;
    use Moo;

    with 'Catmandu::Importer';

    sub generator {
        my ($self) = @_;
        state $fh = $self->fh;
        return sub {
            my $name = $self->readline;
            return defined $name ? { "hello" => $name } : undef;
        };
    } 

=head1 DESCRIPTION

A Catmandu::Importer is a Perl packages that can import data from an external
source (a file, the network, ...). Most importers read from an input stream, 
such as STDIN, a given file, or an URL to fetch data from, so this base class
provides helper method for consuming the input stream once.

Every Catmandu::Importer is a L<Catmandu::Fixable> and thus provides a 'fix'
parameter that can be set in the constructor. For every item returned by the
generator the given fixes will be applied first.

Every Catmandu::Importer is a L<Catmandu::Iterable> and its methods (C<first>,
C<each>, C<to_array>...) should be used to access items from the importer.

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=back

=head1 METHODS

=head2 readline

Read a line from the input stream. Equivalent to C<< $importer->fh->getline >>.

=head2 readall

Read the whole input stream as string.

=head1 SEE ALSO

L<Catmandu::Iterable> , L<Catmandu::Util>

=cut

1;
