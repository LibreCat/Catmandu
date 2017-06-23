package Catmandu::Fix::int;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    my $match_var = $fixer->generate_var;
    <<EOF;
if (is_string(${var}) and my (${match_var}) = ${var} =~ /([+-]?\\d+)/) {
    ${var} = ${match_var} + 0;
} elsif (is_array_ref(${var})) {
    ${var} = scalar(\@{${var}});
} elsif (is_hash_ref(${var})) {
    ${var} = scalar(keys \%{${var}});
} else {
    ${var} = 0;
}
EOF
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::int - convert a value to an integer

=head1 SYNOPSIS

    # year => "2016"
    int(year)
    # year => 2016

    # foo => "bar-123baz"
    int(foo)
    # foo => -123

    # foo => ""
    int(foo)
    # foo => 0

    # foo => "abc"
    int(foo)
    # foo => 0

    # foo => []
    int(foo)
    # foo => 0

    # foo => ["a", "b", "c"]
    int(foo)
    # foo => 3

    # foo => {a => "b", c => "d"}
    int(foo)
    # foo => 2

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
