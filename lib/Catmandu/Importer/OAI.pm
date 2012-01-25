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

=head1 NAME

Catmandu::Importer::OAI - Package that imports OAI-PMH feeds

=head1 SYNOPSIS

    use Catmandu::Importer::OAI;

    my $importer = Catmandu::Importer::OAI->new(url => "...", set => "..." );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new(url => URL,[set => [qw(...)])

Create a new OAI-PMH importer for the URL. Optionally provide a set parameter with the
OAI-PMH set you want to import.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::OAI methods are not idempotent: OAI-PMH feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
