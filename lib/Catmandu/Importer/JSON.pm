package Catmandu::Importer::JSON;

use namespace::clean;
use Catmandu::Sane;
use JSON::XS ();
use Moo;

with 'Catmandu::Importer';

has json      => (is => 'ro', lazy => 1, builder => '_build_json');
has multiline => (is => 'ro', default => sub { 0 });

sub _build_json {
    my ($self) = @_;
    JSON::XS->new->utf8($self->encoding eq ':raw');
}

sub default_encoding { ':raw' }

sub generator {
    my ($self) = @_;

    $self->multiline ? sub {
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

=head2 new(file => $filename , fh => $fh , multiline => 0|1 ,fix => [...])

Create a new JSON importer for C<$filename>. Uses STDIN when no filename is given.
C<multiline> switches optionally between line-delimited JSON and multiline JSON or arrays.
the default is line-delimited JSON.

The constructor inherits the fix parameter from L<Catmandu::Fixable>. When given,
then each fix or fix script will be applied to imported items.

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
