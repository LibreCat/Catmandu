package Catmandu::Fix::parse_text;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);
has pattern => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    my $pattern = $fixer->emit_match($self->pattern);

    "if (is_string(${var}) && ${var} =~ ${pattern}) {" . "if (\@+ < 2) { " .

        # # no capturing groups
        "}" . "elsif (\%+) { " .

        # named capturing groups
        "${var} = { \%+ }; " . "} else {" .

        # numbered capturing groups
        "no strict 'refs';"
        . "${var} = [ map { \${\$_} } 1..(\@{+} - 1) ];" . "}" . "}";
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
