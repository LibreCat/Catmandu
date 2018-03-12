package Catmandu::Util::Regex;

use Catmandu::Sane;

our $VERSION = '1.09';

use Exporter qw(import);

our @EXPORT_OK = qw(
    escape_regex
    as_regex
    substituter
);

our %EXPORT_TAGS = (all => \@EXPORT_OK,);

sub escape_regex {
    my ($str) = @_;
    $str =~ s/\//\\\//g;
    $str =~ s/\\$/\\\\/;    # pattern can't end with an escape
    $str;
}

sub as_regex {
    my ($str) = @_;
    $str = escape_regex($str);
    qr/$str/;
}

sub substituter {
    my ($search, $replace) = @_;
    $search  = as_regex($search);
    $replace = escape_regex($replace);
    eval
        qq|sub {my \$str = \$_[0]; utf8::upgrade(\$str); \$str =~ s/$search/$replace/g; \$str}|;
}

1;
