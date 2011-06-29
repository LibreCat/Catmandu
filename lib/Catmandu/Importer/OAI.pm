package Catmandu::Importer::OAI;
use Catmandu::Sane;
use Catmandu::Object url => 'r', set => 'r', record => 'r';
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

sub _record_to_obj {
    my ($self, $rec) = @_;
    my $obj = { _id => $rec->header->identifier };
    my $metadata = $rec->metadata;
    foreach (@oai_dc_elements) {
        $obj->{$_} = $metadata->{$_};
    }
    $obj;
}

sub each {
    my ($self, $sub) = @_;

    my $harvester = Net::OAI::Harvester->new(baseURL => $self->url);

    if ($self->record) {
        my $rec = $harvester->getRecord(metadataPrefix => 'oai_dc', identifier => $self->record);
        my $obj = $self->_record_to_obj($rec);
        $sub->($obj);
        return 1;
    }

    my $records = $harvester->listAllRecords(
        metadataPrefix => 'oai_dc',
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
