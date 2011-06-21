package Catmandu::Importer::OAI;
use Catmandu::Sane;
use Catmandu::Object url => 'r', set => 'r';
use Net::OAI::Harvester;

my @oai_dc_elements = qw(
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

sub each {
    my ($self, $sub) = @_;

    my $harvester = Net::OAI::Harvester->new(baseURL => $self->url);

    my $records = $harvester->listAllRecords(
        metadataPrefix  => 'oai_dc',
        set => $self->set,
    );

    my $n = 0;

    while (my $rec = $records->next) {
        my $metadata = $rec->metadata;
        my $obj = { _id => $rec->header->identifier };
        foreach (@oai_dc_elements) {
            $obj->{$_} = $metadata->{$_};
        }
        $sub->($obj);
        $n++;
    }

    $n;
}

1;
