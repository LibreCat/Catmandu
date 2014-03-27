package Catmandu::Importer::JSON;

use namespace::clean;
use Catmandu::Sane;
use JSON ();
use Moo;

with 'Catmandu::Importer';

has json      => (is => 'ro', lazy => 1, builder => '_build_json');
has multiline => (is => 'ro', default => sub { 0 });

sub _build_json {
    my ($self) = @_;
    JSON->new->utf8($self->encoding eq ':raw');
}

sub default_encoding { ':raw' }

sub generator {
    my ($self) = @_;

    $self->multiline ? sub {
        state $json = $self->json;
        state $fh   = $self->fh;

        for (;;) {
            sysread($fh, my $buf, 512) // Catmandu::Error->throw($!);
            $json->incr_parse($buf); # void context, so no parsing
            $json->incr_text =~ s/^[^{]+//;
            return unless length $json->incr_text;
            last if $json->incr_text =~ /^\{/;
        }

        # read data until we get a single json object
        my $data;
        for (;;) {
            if ($data = $json->incr_parse) {
                last;
            }

            sysread($fh, my $buf, 512) // Catmandu::Error->throw($!);
            $json->incr_parse($buf);
        }

        $data;
    } : sub {
        state $json = $self->json;
        state $fh   = $self->fh;
        if (defined(my $line = <$fh>)) {
            return $json->decode($line);
        }
        return;
    };
}

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

Use the C<multiline> option to parse pretty-printed JSON or JSON arrays.

=head1 METHODS

=head2 new([file => $filename, multiline => 0|1])

Create a new JSON importer for C<$filename>. Uses STDIN when no filename is given.
C<multiline> switches between line-delimited JSON and multiline JSON or arrays.
the default is line-delimited JSON.

=head2 count

=head2 each(&callback)

=head2 ...

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited. The Catmandu::Importer::JSON methods are not idempotent: JSON
streams can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
