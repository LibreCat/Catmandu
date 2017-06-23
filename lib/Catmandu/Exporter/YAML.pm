package Catmandu::Exporter::YAML;

use Catmandu::Sane;

our $VERSION = '1.0602';

use YAML::XS ();
use Moo;
use namespace::clean;

with 'Catmandu::Exporter';

sub add {
    my ($self, $data) = @_;
    my $yaml = YAML::XS::Dump($data);
    utf8::decode($yaml);
    $self->fh->print($yaml);
    $self->fh->print("...\n");
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::YAML - a YAML exporter

=head1 SYNOPSIS

    # From the commandline
    $ catmandu convert JSON --fix myfixes to YAML < /tmp/data.json

    # From Perl

    use Catmandu;

    # Print to STDOUT
    my $exporter = Catmandu->exporter('YAML', fix => 'myfix.txt');

    # Print to file or IO::Handle
    my $exporter = Catmandu->exporter('YAML', file => '/tmp/out.yml');
    my $exporter = Catmandu->exporter('YAML', file => $fh);

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d objects\n" , $exporter->count;

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

=back

=head1 SEE ALSO

L<Catmandu::Exporter>, L<Catmandu::Importer::YAML>

=cut
