package Catmandu::Exporter::Text;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use Catmandu::Util;
use namespace::clean;

with 'Catmandu::Exporter';

use vars qw(%Interpolated );

# From String::Escape
# Earlier definitions are preferred to later ones, thus we output \n not \x0d
_define_backslash_escapes(
    (map {$_ => $_} ('\\', '"', '$', '@')),
    ('r' => "\r", 'n' => "\n", 't' => "\t"),
    (map {'x' . unpack('H2', chr($_)) => chr($_)} (0 .. 255)),
    (map {sprintf('%03o', $_)         => chr($_)} (0 .. 255)),
);

sub _define_backslash_escapes {
    %Interpolated = @_;
}

# $original_string = unbackslash( $special_characters_escaped );
sub unbackslash ($) {
    local $_ = (defined $_[0] ? $_[0] : '');
    s/ (\A|\G|[^\\]) [\\] ( [0][0-9][0-9] | [x][0-9a-fA-F]{2} | . ) / $1 . ( $Interpolated{lc($2) }) /gsxe;
    return $_;
}

# End from String::Escape

has line_sep => (
    is      => 'ro',
    default => sub {"\n"},
    coerce  => sub {unbackslash($_[0]);}
);
has field_sep => (
    is      => 'ro',
    default => sub {undef},
    coerce  => sub {unbackslash($_[0])}
);

sub add {
    my ($self, $data) = @_;
    my $text = $self->hash_text('', $data);

    $self->fh->print($text);
    $self->fh->print($self->line_sep) if defined $self->line_sep;
}

sub hash_text {
    my ($self, $text, $hash) = @_;

    for my $k (sort keys %$hash) {
        next if ($k =~ /^_.*/);
        my $item = $hash->{$k};

        $text .= $self->field_sep
            if defined $self->field_sep && length($text);

        if (Catmandu::Util::is_array_ref($item)) {
            $text .= $self->array_text($text, $item);
        }
        elsif (Catmandu::Util::is_hash_ref($item)) {
            $text .= $self->hash_text($text, $item);
        }
        else {
            $text .= $item;
        }
    }

    return $text;
}

sub array_text {
    my ($self, $text, $arr) = @_;

    for my $item (@$arr) {
        $text .= $self->field_sep
            if defined $self->field_sep && length($text);

        if (Catmandu::Util::is_array_ref($item)) {
            $text .= $self->array_text($text, $item);
        }
        elsif (Catmandu::Util::is_hash_ref($item)) {
            $text .= $self->hash_text($text, $item);
        }
        else {
            $text .= $item;
        }
    }

    return $text;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::Text - a Text exporter

=head1 SYNOPSIS

    # From the command line

    # Write all field values as a line of Text
    $ catmandu convert JSON to Text --field_sep "," < data.json

    # In a Perl script

    use Catmandu;

    # Print to STDOUT
    my $exporter = Catmandu->exporter('Text', fix => 'myfix.txt');

    # Print to file or IO::Handle
    my $exporter = Catmandu->exporter('Text', file => '/tmp/out.yml');
    my $exporter = Catmandu->exporter('Text', file => $fh);

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d items\n" , $exporter->count;

=head1 DESCRIPTION

This C<Catmandu::Exporter> exports items as raw text. All field values found
in the data will be contactenated using C<field_sep> as delimiter.

=head1 CONFIGURATION

=over 4

=item file

Write output to a local file given by its path or file handle.  Alternatively a
scalar reference can be passed to write to a string and a code reference can be
used to write to a callback function.

=item fh

Write the output to an L<IO::Handle>. If not specified,
L<Catmandu::Util::io|Catmandu::Util/IO-functions> is used to create the output
handle from the C<file> argument or by using STDOUT.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to exported items.

=item encoding

Binmode of the output stream C<fh>. Set to "C<:utf8>" by default.

=item line_sep STR

Use the STR at each end of line. Set to "C<\n>" by default.

=item field_sep STR

Use the STR at each end of a field.

=back

=head1 SEE ALSO

L<Catmandu::Exporter> , L<Catmandu::Importer::Text>

=cut
