package Catmandu::Importer::Luur;

use 5.010;

use Moose;

no strict "subs";

with 'Catmandu::Importer';

use JSON qw(decode_json);
use LWP::Simple;
use Net::OAI::Harvester;

has 'jsonurl' => (
    is      => 'rw' ,
    isa     => 'Str' ,
    default => 'http://biblio.ugent.be/json/' ,
);

has 'metadataPrefix' => (
    is      => 'rw' ,
    isa     => 'Str' ,
    default => 'oai_dc' ,
);

has 'setSpec' => (
    is      => 'rw',
    isa     => 'Str',
);


sub each {
   my ($self, $callback) = @_;

   my $url = $self->file;
   my $fmt = $self->metadataPrefix;
   my $set = $self->setSpec;

   my $harvester = new Net::OAI::Harvester(baseURL => $url);

   my $response = $harvester->listAllIdentifiers(
                        metadataPrefix => $fmt ,
                        set => $set ,
                    );

   my $num = 0;

   while (my $rec = $response->next) {
    $num++;

    my $identifier = $rec->identifier;
    $identifier =~ s/.*://;

    my $json = get($self->jsonurl . "$identifier");
    my $obj  = decode_json($json);

    $obj->{_id} = $identifier;

    &{$callback}($obj) if $callback;
   }

   return $num;
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;
