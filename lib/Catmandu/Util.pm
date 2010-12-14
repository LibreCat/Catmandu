package Catmandu::Util;

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

