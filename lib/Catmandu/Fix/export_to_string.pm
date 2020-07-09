package Catmandu::Fix::export_to_string;

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
    as_path($self->path)->updater(
        if => [
            [qw(array_ref hash_ref)] =>
                sub {Catmandu->export_to_string($_[0], $name, %$opts)}
        ]
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::export_to_string - convert the value of field using a named exporter

=head1 SYNOPSIS

    export_to_string(my.field,'YAML')

    export_to_string(my.field2,'JSON')

    export_to_string(my.field3,'CSV', 'sep_char' => ';' )

=head1 DESCRIPTION

=head2 export_string( PATH, NAME [, EXPORT_OPTIONS ] )

This fix uses the function export_to_string of the package L<Catmandu>, but requires the NAME of the exporter.

It expects a HASH or ARRAY as input. Other values are silently ignored.

=over 4

=item PATH

=item NAME

name of the exporter to use. As usual in Catmandu, one can choose:

* full package name of the exporter (e.g. 'Catmandu::Exporter::JSON')

* short package name of the exporter (e.g. 'JSON')

* name of the exporter as declared in the Catmandu configuration

=item EXPORT_OPTIONS

extra options for the named exporter

=back

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

