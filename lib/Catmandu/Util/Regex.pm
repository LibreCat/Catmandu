package Catmandu::Util::Regex;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Exporter qw(import);

our @EXPORT_OK = qw(
    escape_regex
    as_regex
    substituter
);

our %EXPORT_TAGS = (all => \@EXPORT_OK,);

sub _escape_regex {
    my ($str) = @_;
    $str =~ s/\//\\\//g;
    $str =~ s/\\$/\\\\/;    # pattern can't end with an escape
    $str;
}

sub as_regex {
    my ($str) = @_;
    $str = _escape_regex($str);
    qr/$str/;
}

sub substituter {
    my ($search, $replace) = @_;
    $search  = as_regex($search);
    $replace = _escape_regex($replace);
    eval
        qq|sub {my \$str = \$_[0]; utf8::upgrade(\$str); \$str =~ s/$search/$replace/g; \$str}|;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Util::Regex - Regex related utility functions

=head1 FUNCTIONS

=over 4

=item as_regex($str)

Escapes and quotes the given string as a regex.

=item substituter($search, $replace)

Builds a function that performs a regex substitution.

    my $ltrimmer = substituter('^[\h\v]+', '');
    $ltrimmer->("        eek! ");
    # => "eek! "

=back

=cut
