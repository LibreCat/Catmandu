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

sub _rec_to_obj {
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

    my $oai = Net::OAI::Harvester->new(baseURL => $self->url);
    my $res;

    if ($self->record) {
        $res = $oai->getRecord(identifier => $self->record, metadataPrefix => 'oai_dc');

        if ($res->errorCode) {
            return 0;
        }

        my $obj = $self->_rec_to_obj($res);
        $sub->($obj);
        return 1;
    }

    $res = $oai->listAllRecords(set => $self->set, metadataPrefix => 'oai_dc');

    if ($res->errorCode) {
        return 0;
    }

    my $n = 0;

    while (my $rec = $res->next) {
        my $obj = $self->_rec_to_obj($rec);
        $sub->($obj);
        $n++;
    }

    $n;
}

1;
