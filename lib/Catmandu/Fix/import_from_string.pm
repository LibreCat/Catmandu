package Catmandu::Fix::import_from_string;

use Catmandu::Sane;

our $VERSION = '1.0306';

use Moo;
use Catmandu;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);
has name => (fix_arg => 1,required => 0);
has import_opts => (fix_arg => 'collect')

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    my $import_opts = $fixer->capture( $self->import_opts );
    my $name = $self->name();
    "${var} = Catmandu->import_from_string( ${var}, '$name', %${import_opts} );";
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Catmandu::Fix::import_from_string - Import data from a string into an array ref, using a default or named importer.

=head1 SYNOPSIS

    #{ 'json' => '[{"name":"Nicolas"}]' } => { 'json' => [{"name":"Nicolas"}] }
    import_from_string('json','JSON')

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Importer>

=cut
