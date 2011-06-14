package Catmandu::Exporter::DC;
use Catmandu::Sane;
use Catmandu::Util qw(io quack);
use XML::LibXML;
use Catmandu::Object file => { default => sub { *STDOUT } };

my $oai_dc_ns = "http://www.openarchives.org/OAI/2.0/oai_dc/";
my $dc_ns = "http://purl.org/dc/elements/1.1/";
my $xsi_ns = "http://www.w3.org/2001/XMLSchema-instance";
my $oai_dc_schema = "http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd";
my @dc_keys = qw(
    title
    creator
    subject
    description
    publisher
    contributor
    date
    type
    format
    identifier
    source
    language
    relation
    coverage
    rights
);

sub add { # TODO handle each
    my ($self, $obj) = @_;

    confess "TODO" if quack $obj, 'each';

    my $file = io $self->file, 'w';

    my $xml  = XML::LibXML->createDocument('1.0', 'UTF-8');
    my $root = $xml->createElementNS($oai_dc_ns, 'dc');
    $root->setNamespace($oai_dc_ns, 'oai_dc', 1);
    $root->setNamespace($dc_ns, 'dc', 0);
    $root->setNamespace($xsi_ns, 'xsi', 0);
    $root->setAttributeNS($xsi_ns, 'schemaLocation', $oai_dc_schema);
    $xml->setDocumentElement($root);
    for my $key (@dc_keys) {
        my $val = $obj->{$key} || next;
        $root->addNewChild($dc_ns, $key)->appendText($_) for @$val;
    }

    print $file $xml->toString;
    1;
}

1;
