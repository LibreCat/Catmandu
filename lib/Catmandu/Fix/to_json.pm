package Catmandu::Fix::to_json;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Cpanel::JSON::XS ();
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;

    # memoize in case called multiple times
    my $json_var = $fixer->capture(
        Cpanel::JSON::XS->new->utf8(0)->pretty(0)->allow_nonref(1));

    "if (is_maybe_value(${var}) || is_array_ref(${var}) || is_hash_ref(${var})) {"
        . "${var} = ${json_var}->encode(${var});" . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::to_json - convert the value of a field to json

=head1 SYNOPSIS

   to_json(my.field)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

