package Catmandu::Fix::string;

use Catmandu::Sane;

our $VERSION = '1.0602';

use List::Util ();
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    <<EOF;
if (is_string(${var})) {
    ${var} = '' . ${var};
} elsif (is_array_ref(${var}) && List::Util::all { is_value(\$_) } \@{${var}}) {
    ${var} = join('', \@{${var}});
} elsif (is_hash_ref(${var}) && List::Util::all { is_value(\$_) } values \%{${var}}) {
    ${var} = join('', map { ${var}->{\$_} } sort keys \%{${var}});
} else {
    ${var} = '';
}
EOF
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::string - convert a value to a string

=head1 SYNOPSIS

    # year => 2016
    string(year)
    # year => "2016"

    # foo => ["a", "b", "c"]
    string(foo)
    # foo => "abc"

    # foo => ["a", {b => "c"}, "d"]
    string(foo)
    # foo => ""
    
    # foo => {2 => "b", 1 => "a"}
    string(foo)
    # foo => "ab"

    # foo => {a => ["b"]}
    string(foo)
    # foo => ""

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
