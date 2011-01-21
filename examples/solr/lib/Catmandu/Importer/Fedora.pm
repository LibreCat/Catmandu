package Catmandu::Importer::Fedora;

use 5.010;

use Moose;
use Data::UUID;

no strict "subs";

extends 'Catmandu::Importer::JSON';

with 'Catmandu::Importer';

our $sfx_resolver = 'http://adore.ugent.be/OpenURL/resolve?rft_id=%s&svc_id=%s&url_ver=Z39.88-2004';

sub each {
   my ($self, $callback) = @_;
   my $num = 0;

   $self->SUPER::each( sub {
       my $obj = shift;
       my $rec = $self->parse($obj);

       if ($rec && $callback) {
          &$callback($rec);
          $num++;
       }
   });

   $num;
}

sub parse {
   my ($self, $obj) = @_;

   return undef unless $self->select_obj($obj);

   my $rec = {};
   my @media = ();

   my $num = 1;
   foreach my $ds (@{$obj->{objectDatastreams}}) {
       next unless $ds->{dsid}  =~ /^DS\.\d+/;
       next unless $ds->{label} =~ /_MA\.\w+$/;

       my $file  = $ds->{label};
       $file     =~ s/_MA/_AC/;
       my $objid = $file;
       $objid    =~ s/\.\w+$//;

       push @media, {
            services => [qw(thumbnail small medium large)] ,
            access   => 'public' ,
            file     => [ $file ] , 
            item_id  => $num ,
            sizes    => {
                thumbnail => sprintf($sfx_resolver, $objid , 'Thumbnail') ,
                small     => sprintf($sfx_resolver, $objid , 'Small') ,
                medium    => sprintf($sfx_resolver, $objid , 'Medium') ,
                large     => sprintf($sfx_resolver, $objid , 'Large') ,
            } ,
       };

       $num++;
   }

   $rec->{media} = [ @media ]; 
   $rec->{_id} = $self->find_rug01($obj) || Data::UUID->new->create_str();
   
   $rec;
}

# Return true when a fedora object contains the required metata
sub select_obj {
   my ($self, $obj) = @_;

   foreach my $ds (@{$obj->{objectDatastreams}}) {
       return 1 if $ds->{dsid} =~ /^DS\.\d+/ && $ds->{label} =~ /_MA\.(tif|jpg)$/i;
   }

   undef;
}

# Return the rug01 of the object
sub find_rug01 {
   my ($self, $obj) = @_;

   return undef unless $obj->{dc}->{identifier};

   my (@ids) = grep { /^(rug01:)?\d{9}$/ } @{ $obj->{dc}->{identifier} };

   return undef unless @ids > 0;

   my $rug01 = $ids[0];

   $rug01 =~ /^rug01:/ ? $rug01 : "rug01:$rug01";
} 

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;
