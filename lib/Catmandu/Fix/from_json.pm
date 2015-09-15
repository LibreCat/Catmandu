package Catmandu::Fix::from_json;

use Catmandu::Sane;
use JSON::XS ();
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);
has _json_var => (is => 'rwp', writer => '_set_json_var', init_arg => undef);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    # memoize in case called multiple times
    my $json_var = $self->_json_var ||
                   $self->_set_json_var($fixer->capture(JSON::XS->new->utf8(0)->pretty(0)->allow_nonref(1)));

    "if (is_string(${var})) {" .
        "${var} = ${json_var}->decode(${var});" .
    "}";
}

=head1 NAME

Catmandu::Fix::from_json - replace a json field with the parsed value

=head1 SYNOPSIS

   from_json(my.field)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;


