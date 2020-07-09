package Catmandu::Fix::import_from_string;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);
has name => (fix_arg => 1);
has opts => (fix_opt => 'collect');

sub _build_fixer {
    my ($self) = @_;
    my $name   = $self->name;
    my $opts   = $self->opts;
    as_path($self->path)
        ->updater(
        if_string => sub {Catmandu->import_from_string($_[0], $name, %$opts)}
        );
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Catmandu::Fix::import_from_string - Import data from a string into an array ref, using a named importer.

=head1 SYNOPSIS

    #BEFORE: { 'json' => '[{"name":"Nicolas"}]' }
    #AFTER:  { 'json' => [{"name":"Nicolas"}] }

    import_from_string('json','JSON')

    #BEFORE: { record => qq(first_name;name\nNicolas;Franck\nPatrick;Hochstenbach\n) }
    #AFTER:  { record => [{ "first_name" => "Nicolas",name => "Franck" },{ "first_name" => "Patrick",name => "Hochstenbach" }] }

    import_from_string('record','CSV', 'sep_char' => ';')


=head1 DESCRIPTION

=head2 import_from_string( PATH, NAME [, IMPORT_OPTIONS ] )

This fix uses the function import_from_string of the package L<Catmandu>, but requires the NAME of the importer.

It always returns an array of hashes.

=over 4

=item PATH

=item NAME

name of the importer to use. As usual in Catmandu, one can choose:

* full package name of the importer (e.g. 'Catmandu::Importer::JSON')

* short package name of the importer (e.g. 'JSON')

* name of the importer as declared in the Catmandu configuration

=item IMPORT_OPTIONS

extra options for the named importer

=back

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Importer>

=cut
