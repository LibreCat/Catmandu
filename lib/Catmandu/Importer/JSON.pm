package Catmandu::Importer::JSON;

use namespace::clean;
use Catmandu::Sane;
use JSON::XS ();
use Moo;

with 'Catmandu::Importer';

has json      => (is => 'ro', lazy => 1, builder => '_build_json');
has multiline => (is => 'ro', default => sub { 0 });
has array     => (is => 'ro', default => sub { 0 });

sub _build_json {
    my ($self) = @_;
    JSON::XS->new->utf8($self->encoding eq ':raw');
}

sub default_encoding { ':raw' }

sub generator {
    my ($self) = @_;

    $self->multiline || $self->array ? sub {
        state $json = $self->json;
        state $fh   = $self->fh;

        for (;;) {
            my $res = sysread($fh, my $buf, 512);
            $res // Catmandu::Error->throw($!);
            $json->incr_parse($buf); # void context, so no parsing
            $json->incr_text =~ s/^[^{]+//;
            return if $json->incr_text =~ /^$/;
            last if $json->incr_text =~ /^{/;
        }

        # read data until we get a single json object
        for (;;) {
            if (my $data = $json->incr_parse) {
                return $data;
            }

            my $res = sysread($fh, my $buf, 512);
            $res // Catmandu::Error->throw($!);
            $res || Catmandu::Error->throw("JSON syntax error: unexpected end of object");
            $json->incr_parse($buf);
        }

        return;
 
    } : sub {
        state $json = $self->json;
        state $fh   = $self->fh;
        if (defined(my $line = <$fh>)) {
            return $json->decode($line);
        }
        return;
    };
}

1;
__END__

=head1 NAME

Catmandu::Importer::JSON - Package that imports JSON data

=head1 SYNOPSIS

    use Catmandu::Importer::JSON;

    my $importer = Catmandu::Importer::JSON->new(file => "/foo/bar.json");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

The defaults assume a newline delimited JSON file:

    { "recordno": 1, "name": "Alpha" }
    { "recordno": 2, "name": "Beta" }
    { "recordno": 3, "name": "Gamma" }

Use the C<multiline> or C<array> options to parse pretty-printed JSON or JSON
arrays.

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

=item multiline

=item array

Read JSON with line-breaks or a JSON array instead of line-delimited JSON

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited. The methods are not idempotent: JSON streams can only be read once.

=head1 SEE ALSO

L<Catmandu::Exporter::JSON>

=cut
