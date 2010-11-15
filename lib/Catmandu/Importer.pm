package Catmandu::Importer;

use Moose::Role;

requires 'load';
requires 'each';

has 'file' => (
    is       => 'ro',
    required => 1,
    builder  => '_build_file',
);

sub _build_file {
    \*STDIN;
}

no Moose::Role;
__PACKAGE__;

__END__

=head1 NAME

Catmandu::Importer - role describing an importer.

=head1 SYNOPSIS

    my $array_ref = $importer->load;

    $importer->each(sub {
        my $obj = $_[0];
        ...
    });

=head1 METHODS

=head2 $c->file

Returns the stream from which objects are imported. Defaults to C<STDIN>.

=head2 $c->load

Imports al the objects in C<file> and returns
the objects as an arrayref of hashrefs.

=head2 $c->each($sub)

Iterates over all objects in C<file> and passes them to C<$sub>.
Returns the number of objects imported.

