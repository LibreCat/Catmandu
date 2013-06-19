package Catmandu::Fix::from_json;

use Catmandu::Sane;
use Moo;
use JSON ();

with 'Catmandu::Fix::Base';

has path => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    $orig->($class, path => $path);
};

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    my $json_var = $fixer->capture(JSON->new->utf8(0)->pretty(0)->allow_nonref(1));

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "if (is_string(${var})) {" .
                "${var} = ${json_var}->decode(${var});" .
            "}";
        });
    });
}

=head1 NAME

Catmandu::Fix::from_json - replace a json field with the parsed value

=head1 SYNOPSIS

   to_json('my.field');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;


