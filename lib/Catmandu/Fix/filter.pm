package Catmandu::Fix::filter;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path   => (fix_arg => 1);
has search => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;

    "if (is_array_ref(${var})) {"
        . "${var} = [ grep { "
        . $fixer->emit_match($self->search)
        . " } \@{${var}} ];" . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::filter - Filter values out of an array based on a regular expression

=head1 SYNOPSIS

   # words => ["Patrick","Nicolas","Paul","Frank"]
   
   filter(words,'Pa')
   
   # words => ["Patrick","Paul"]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
