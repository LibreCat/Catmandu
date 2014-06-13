package Catmandu::Exporter::JSON;

use namespace::clean;
use Catmandu::Sane;
use JSON ();
use Moo;

with 'Catmandu::Exporter';

has pretty       => (is => 'ro', default => sub { 0 });
has indent       => (is => 'ro', default => sub { 0 });
has space_before => (is => 'ro', default => sub { 0 });
has space_after  => (is => 'ro', default => sub { 0 });
has canonical    => (is => 'ro', default => sub { 0 });
has array        => (is => 'ro', default => sub { 0 });
has json         => (is => 'ro', lazy => 1, builder => '_build_json');

sub _build_json {
    my ($self) = @_;
    JSON->new
        ->utf8(0)
        ->allow_nonref
        ->pretty($self->pretty)
        ->indent($self->pretty || $self->indent)
        ->space_before($self->pretty || $self->space_before)
        ->space_after($self->pretty || $self->space_after)
        ->canonical($self->canonical);
}

sub add {
    my ($self, $data) = @_;
    my $fh = $self->fh;
    my $json = $self->json->encode($data);
    if ($self->pretty) {
        chomp $json;
    }
    if ($self->array) {
        if ($self->count) {
            print $fh ",";
            print $fh "\n" if $self->pretty;
        } else {
            print $fh "[";
        }
        print $fh $json;
    } else {
        print $fh $json;
        print $fh "\n";
    }
}

sub commit {
    my ($self, $data) = @_;
    if ($self->array) {
        my $fh = $self->fh;
        unless ($self->count) {
            print $fh "[";
        }
        print $fh "]\n";
    }
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

=head2 new(file => PATH, fh => HANDLE, fix => STRING|ARRAY, pretty => 0|1, array => 0|1)

Create a new JSON exporter optionally providing a file path, a file handle, a fix file or array and a pretty printing option.

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

1;
