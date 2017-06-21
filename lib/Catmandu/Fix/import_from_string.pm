package Catmandu::Fix::import_from_string;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use Catmandu;
use namespace::clean;
use Catmandu::Fix::Has;

has path        => (fix_arg => 1);
has name        => (fix_arg => 1);
has import_opts => (fix_opt => 'collect');

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    my $import_opts = $fixer->capture($self->import_opts);
    my $name        = $self->name();
    "${var} = Catmandu->import_from_string( ${var}, '$name', %${import_opts} );";
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
