package Catmandu::Fix::from_json;

use Catmandu::Sane;

our $VERSION = '1.06';

use Cpanel::JSON::XS ();
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    my $json_var = $fixer->capture(
        Cpanel::JSON::XS->new->utf8(0)->pretty(0)->allow_nonref(1));

    "if (is_string(${var})) {"
        . "${var} = ${json_var}->decode(${var});" . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::from_json - replace a json field with the parsed value

=head1 SYNOPSIS

   from_json(my.field)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut


