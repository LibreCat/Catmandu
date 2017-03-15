package Catmandu::Fix::export_to_string;

use Catmandu::Sane;

our $VERSION = '1.0306';

use Moo;
use Catmandu;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);
has name => (fix_arg => 1);
has export_opts => (fix_opt => 'collect');

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;

    my $name = $self->name();
    my $export_opts = $fixer->capture( $self->export_opts );
    my $perl = <<EOF;

if( is_hash_ref( ${var} ) || is_array_ref( ${var} ) ) {

    ${var} = Catmandu->export_to_string( ${var}, '$name', %${export_opts} );

}

EOF

    $perl;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::export_to_string - convert the value of field using a named exporter

=head1 SYNOPSIS

    #value MUST be hash or array reference. Other values are ignored

    export_to_string(my.field,'YAML')

    export_to_string(my.field2,'JSON')

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

