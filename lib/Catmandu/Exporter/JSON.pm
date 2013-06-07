package Catmandu::Exporter::JSON;

use namespace::clean;
use Catmandu::Sane;
use JSON ();
use Moo;

with 'Catmandu::Exporter';

has pretty => (is => 'ro', default => sub { 0 });
has json   => (is => 'ro', lazy => 1, builder => '_build_json');

sub _build_json {
     JSON->new->utf8(0)->pretty($_[0]->pretty);
}

sub add {
    my ($self, $data) = @_;
    my $fh = $self->fh;
    say $fh $self->json->encode($data);
}

=head1 NAME

Catmandu::Exporter::JSON - a JSON exporter

=head1 SYNOPSIS

    use Catmandu::Exporter::JSON;

    my $exporter = Catmandu::Exporter::JSON->new(fix => 'myfix.txt');

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d objects\n" , $exporter->count;

=head1 METHODS

=head2 new(file => PATH, fh => HANDLE, fix => STRING|ARRAY, pretty => 1)

Create a new JSON exporter optionally providing a file path, a file handle, a fix file or array and a pretty printing option.

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

1;
