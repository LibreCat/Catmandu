package Catmandu::Fix::parse_text;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Util::Regex qw(as_regex);
use namespace::clean;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);
has pattern => (fix_arg => 1);

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;
    my $regex = as_regex($self->pattern);
    as_path($self->path)->updater(
        if_string => sub {
            my $val = $_[0];
            if ($val =~ m/$regex/) {
                if (@+ < 2) {    # no capturing groups
                    return undef, 1, 0;
                }
                elsif (%+) {     # named capturing groups
                    return +{%+};
                }
                else {           # numbered capturing groups
                    no strict 'refs';
                    return [map {${$_}} 1 .. (@+ - 1)];
                }
            }
            return undef, 1, 0;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::parse_text - parses a text into an array or hash of values

=head1 SYNOPSIS

    # date: "2015-03-07"
    parse_text(date, '(\d\d\d\d)-(\d\d)-(\d\d)')
    # date: 
    #    - 2015
    #    - 03
    #    - 07 

    # date: "2015-03-07"
    parse_text(date, '(?<year>\d\d\d\d)-(?<month>\d\d)-(?<day>\d\d)')
    # date:
    #   year: "2015"
    #   month: "03" 
    #   day: "07"

    # date: "abcd"
    parse_text(date, '(\d\d\d\d)-(\d\d)-(\d\d)')
    # date: "abcd"

=head1 SEE ALSO

L<Catmandu::Fix>

L<Catmandu::Importer::Text>

=cut
