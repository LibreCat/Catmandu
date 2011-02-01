package Catmandu::Importer;
# ABSTRACT: Role describing an importer
# VERSION
use Moose::Role;

requires 'default_attribute';
requires 'each';

no Moose::Role;
1;

=head1 SYNOPSIS

    $importer->each(sub {
        my $obj = $_[0];
        ...
    });

=head1 METHODS

=head2 $c->file

Returns the io from which objects are imported. Defaults to C<STDIN>.

=head2 $c->each($sub)

Iterates over all objects in C<file> and passes them to C<$sub> as a hashref.
Returns the number of objects imported.

