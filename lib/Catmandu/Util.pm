package Catmandu::Util;
# ABSTRACT: Utility functions for Catmandu
# VERSION
use Plack::Util;
use Sub::Exporter -setup => {
    exports => [qw(
        load_class
        unquote
        quoted
        trim
    )],
};

sub load_class {
    Plack::Util::load_class(@_);
}

sub unquote {
    my $str = $_[0];

    if ($str) {
        $str =~ s/^\"(.*)\"$/$1/s or
        $str =~ s/^\'(.*)\'$/$1/s;
    }

    $str;
}

sub quoted {
    my $str = $_[0]; $str and $str =~ /^\"(.*)\"$/ or $str =~ /^\'(.*)\'$/;
}

sub trim {
    my $str = $_[0];

    if ($str) {
        $str =~ s/^\s+//s;
        $str =~ s/\s+$//s;
    }

    $str;
}

1;

=head1 SYNOPSIS

=head1 EXPORTABLE FUNCTIONS

=head2 unquote($str)

If C<$str> starts and ends with matching single or double quotes,
removes them and returns C<$str>.

=head2 quoted($str)

Returns 1 if C<$str> begins and ends with matching
single or double quotes, 0 otherwise.

=head2 trim($str)

Removes leading and trailing whitespace from C<$str> and returns it.

=head1 CREDITS

C<unquote> and C<trim> stolen from L<String::Util>.

