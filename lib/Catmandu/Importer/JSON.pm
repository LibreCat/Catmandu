package Catmandu::Importer::JSON;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Cpanel::JSON::XS ();
use Moo;
use namespace::clean;

with 'Catmandu::Importer';

has line_delimited => (is => 'ro', default => sub {0});
has json => (is => 'lazy');

sub _build_json {
    my ($self) = @_;
    Cpanel::JSON::XS->new->utf8($self->encoding eq ':raw');
}

sub _build_encoding {':raw'}

sub generator {
    my ($self) = @_;

    if ($self->line_delimited) {
        return sub {
            state $json = $self->json;
            state $fh   = $self->fh;
            if (defined(my $line = <$fh>)) {
                return $json->decode($line);
            }
            return;
        };
    }

    # switch to slower incremental parser
    sub {
        state $json = $self->json;
        state $fh   = $self->fh;

        for (;;) {
            my $res = sysread($fh, my $buf, 512);
            $res // Catmandu::Error->throw($!);
            $json->incr_parse($buf);    # void context, so no parsing
            $json->incr_text =~ s/^[^{]+//;
            return if $json->incr_text =~ /^$/;
            last   if $json->incr_text =~ /^{/;
        }

        # read data until we get a single json object
        for (;;) {
            if (my $data = $json->incr_parse) {
                return $data;
            }

            my $res = sysread($fh, my $buf, 512);
            $res // Catmandu::Error->throw($!);
            $res
                || Catmandu::Error->throw(
                "JSON syntax error: unexpected end of object");
            $json->incr_parse($buf);
        }

        return;

    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::JSON - Package that imports JSON data

=head1 SYNOPSIS

    # From the command line
    
    $ catmandu convert JSON to YAML < data.json

    # or for faster newline delimited input

    $ catmandu convert JSON --line_delimited 1 to YAML < data.json

    # In a Perl script

    use Catmandu;

    my $importer = Catmandu->importer('JSON', file => "/foo/bar.json");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 DESCRIPTION

This package imports JSON data. The parser is quite liberal in the input 
it accepts. You can use the C<line_delimited> option to parse "newline 
delimited JSON" faster:

    { "recordno": 1, "name": "Alpha" }
    { "recordno": 2, "name": "Beta" }
    { "recordno": 3, "name": "Gamma" }

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=item line_delimited

Read line-delimited JSON with a faster, non-incremental parser.

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited. The methods are not idempotent: JSON streams can only be read once.

=head1 SEE ALSO

L<Catmandu::Exporter::JSON>

=cut
