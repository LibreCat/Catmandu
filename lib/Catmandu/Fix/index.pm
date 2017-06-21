package Catmandu::Fix::index;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;
use List::MoreUtils;

has path     => (fix_arg => 1);
has search   => (fix_arg => 1);
has multiple => (fix_opt => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;

    my $search   = $fixer->emit_string($self->search);
    my $multiple = $fixer->emit_string($self->multiple);

    my $perl = <<EOF;
if (${multiple}) {
    if (is_string(${var})) {
        ${var} = [ List::MoreUtils::indexes {\$_ eq ${search} } unpack('(A)*',${var}) ] ;
    }
    elsif (is_array_ref(${var})) {
        ${var} = [ List::MoreUtils::indexes {\$_ eq ${search} } \@{${var}} ];
    }
}
else {
    if (is_string(${var})) {
        ${var} = index(${var},${search})
    }
    elsif (is_array_ref(${var})) {
        ${var} = List::MoreUtils::first_index {\$_ eq ${search} } \@{${var}}
    }
}
EOF

    $perl;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::index - Find all positions of a (sub)string in a field

=head1 SYNOPSIS

   # On strings, search the occurence of a character in a string

   # word => "abcde"
   index(word,'c')                   # word => 2
   index(word,'x')                   # word => -1

   # word => "abccde"
   index(word,'c', multiple:1)       # word => [2,3]

   # word => [a,b,bba] , loop over all word(s) with the '*'
   index(word.*,'a')                 # word -> [0,-1,2]

   # On arrays, search the occurence of a word in an array

   # words => ["foo","bar","foo"]
   index(words,'bar')                # words => 1
   index(words,'foo', multiple: 1)   # words => [0,2]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
