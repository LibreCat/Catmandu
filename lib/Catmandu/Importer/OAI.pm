package Catmandu::Importer::OAI;

use Catmandu::Sane;
use Moo;
use Net::OAI::Harvester;

my $OAI_DC_ELEMENTS = [qw(
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
)];

with 'Catmandu::Importer';

has url => (is => 'ro', required => 1);
has set => (is => 'ro');
has oai => (is => 'ro', lazy => 1, builder => '_build_oai');

sub _build_oai {
    Net::OAI::Harvester->new(baseURL => $_[0]->url);
}

sub _map_record {
    my ($self, $rec) = @_;
    my $data = {_id => $rec->header->identifier};
    for my $key (@$OAI_DC_ELEMENTS) {
        my $val = $rec->metadata->{$key};
        $data->{$key} = $val if @$val;
    }
    $data;
}

sub generator {
    my ($self) = @_;
    sub {
        state $res = $self->set
            ? $self->oai->listAllRecords(metadataPrefix => 'oai_dc', set => $self->set)
            : $self->oai->listAllRecords(metadataPrefix => 'oai_dc');
        return if $res->errorCode;
        if (my $rec = $res->next) {
            return $self->_map_record($rec);
        }
        return;
    };
}

1;
