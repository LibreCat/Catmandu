package Catmandu::Exporter::Template;
# ABSTRACT: Export data via a Template Toolkit template
# VERSION
use 5.010;
use Moose;

with qw(
    Catmandu::FileWriter
    Catmandu::Exporter
);

has template => (
    is => 'ro',
    isa => 'Str|ScalarRef|GlobRef',
    required => 1,
    documentation => 'Template to use for the conversion',
);

sub dump {
    my ($self, $obj) = @_;

    my $tmpl = $self->template;
    my $file = $self->file;

    if (ref $obj eq 'ARRAY') {
        Catmandu->print_template($tmpl, $_, $file) for @$obj;
        return scalar @$obj;
    }
    if (ref $obj eq 'HASH') {
        Catmandu->print_template($tmpl, $obj, $file);
        return 1;
    }
    if (blessed $obj and $obj->can('each')) {
        return $obj->each(sub {
            Catmandu->print_template($tmpl, $_[0], $file);
        });
    }

    confess "Can't export object";
}

sub _dump {
    my ($self,$obj) = @_;
    my $output = '';
    my $io = IO::String->new($output);

    Catmandu->print_template($self->template, $obj, $io);

    $self->file->print($output);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 SYNOPSIS

    use Catmandu::Exporter::Template;

    my $exporter = Catmandu::Exporter::Template(template => 'oai_dc.xml');

    # Dump a HASH, ARRAY or something that can so ->each
    $exporter->dump($obj);

    or via the command line

    # Export an import file
    catmandu convert -I Aleph -i map=data/aleph.map -O Template -o template=oai_dc.xml import.txt

    # Export a Simple store
    catmandu export -O Template -o template=oai_dc.xml data/aleph.db

=head1 METHODS

=head2 $c->new(file => $file , template => $file)

Creates a new Catmandu::Exporter for serializing internal Perl hashes. As output
IO stream 'file' will be used (default connected to STDOUT). Mandatory is a template
which contains the path to a Template Toolkit file.

=head2 $c->dump($obj)

Serialize an object $obj. This $obj can be a Perl hash, a Perl ARRAY or an object
implementing 'each'.

=head1 SEE ALSO

L<Catmandu::Exporter>
