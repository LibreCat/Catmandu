package Catmandu::Fix::filter;

use Catmandu::Sane;

our $VERSION = '1.09';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path   => (fix_arg => 1);
has search => (fix_arg => 1);
has invert => (fix_opt => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;

    my $match = $fixer->emit_match($self->search);
    $match = "!$match" if $self->invert;

    "if (is_array_ref(${var})) {"
        . "${var} = [ grep { $match } \@{${var}} ];" . "}";
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
   
   # filter only values that do NOT match the pattern:
   filter(words, 'Pa', invert: 1)
   # words => ["Nicolas","Frank"]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
