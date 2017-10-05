package Catmandu::Exporter::JSON;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Cpanel::JSON::XS ();
use Moo;
use namespace::clean;

with 'Catmandu::Exporter';

has line_delimited => (is => 'ro', default => sub {0});
has array          => (is => 'ro', default => sub {1});
has pretty         => (is => 'ro', default => sub {0});
has indent         => (is => 'ro', default => sub {0});
has space_before   => (is => 'ro', default => sub {0});
has space_after    => (is => 'ro', default => sub {0});
has canonical      => (is => 'ro', default => sub {0});
has json           => (is => 'lazy');

sub _build_json {
    my ($self) = @_;
    Cpanel::JSON::XS->new->utf8(0)
        ->allow_nonref->pretty($self->line_delimited ? 0 : $self->pretty)
        ->indent($self->line_delimited ? 0 : $self->pretty || $self->indent)
        ->space_before($self->line_delimited ? 0 : $self->pretty
            || $self->space_before)
        ->space_after($self->line_delimited ? 0 : $self->pretty
            || $self->space_after)->canonical($self->canonical);
}

sub add {
    my ($self, $data) = @_;
    my $fh   = $self->fh;
    my $json = $self->json->encode($data);
    if ($self->line_delimited) {
        print $fh $json;
        print $fh "\n";
        return;
    }

    if ($self->pretty) {
        chomp $json;
    }
    if ($self->array) {
        if ($self->count) {
            print $fh ",";
            print $fh "\n" if $self->pretty;
        }
        else {
            print $fh "[";
        }
    }
    print $fh $json;
}

sub commit {
    my ($self, $data) = @_;
    if (!$self->line_delimited && $self->array) {
        my $fh = $self->fh;
        unless ($self->count) {
            print $fh "[";
        }
        print $fh "]\n";
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::JSON - a JSON exporter

=head1 SYNOPSIS

    # From the command line

    catmandu convert YAML to JSON --pretty 1 < input.yml

    # Export in the line-delimited format
    catmandu convert YAML to JSON --line_delimited 1 < input.yml

    # In a Perl script

    use Catmandu;

    my $exporter = Catmandu->exporter('JSON', fix => 'myfix.txt');

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d objects\n" , $exporter->count;

=head1 DESCRIPTION

This L<Catmandu::Exporter> exports items serialized in JSON format. By default
each item is printed condensed on one line.

=head1 CONFIGURATION

=over

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

=item pretty

Pretty-print JSON

=item indent

=item space_before

=item space_after

=item canonical

L<JSON> serialization options

=item array

Structure the data as a JSON array. Default is C<1>.

=item line_delimited

Export objects as newline delimited JSON. Default is C<0>. The C<array>, C<pretty>, C<indent>, C<space_before> and C<space_after> options will be ignored if C<line_delimited> is C<1>.

=back

=head1 SEE ALSO

L<Catmandu::Exporter::YAML>

=cut
