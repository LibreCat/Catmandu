package Catmandu::Fix::marc_xml;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Moo;

has path  => (is => 'ro' , required => 1);
has key   => (is => 'ro' , required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    my ($p,$key) = parse_data_path($path) if defined $path && length $path;
    $orig->($class, path => $p, key => $key);
};

# Transform a raw MARC array into MARCXML
sub fix {
    my ($self, $data) = @_;

    my $path  = $self->path;
    my $key   = $self->key;

    my $match = [ grep ref, data_at($path, $data, key => $key, create => 1)]->[0];

    my $marcxml = &marc_header;
 
    for my $f (@{$data->{record}}) { 
        my ($tag,$ind1,$ind2,@data) = @$f; 

        if ($tag eq 'LDR') { 
           $marcxml .= &marc_leader(join("",@data));
        } 
        elsif ($tag =~ /^00/) { 
           shift @data; 
           $marcxml .= &marc_controlfield($tag, join("",@data));
        } 
        elsif ($tag !~ /^00.|FMT|LDR/) { 
           $marcxml .= &marc_datafield($tag,@data);
        }  
    }

    $marcxml .= &marc_footer;

    $match->{$key} = $marcxml;

    $data;
}

sub marc_header {
    "<marc:record xmlns:marc=\"http://www.loc.gov/MARC21/slim\">";
}

sub marc_leader {
    "<marc:leader>" . xml_escape($_[0]) . "</marc:leader>";
}

sub marc_controlfield {
    "<marc:controlfield tag=\"" . xml_escape($_[0]) . "\">" . xml_escape($_[1]) . "</marc:controlfield>";
}

sub marc_datafield {
    my ($tag,$ind1,$ind2,@subfields) = @_;
    my $buffer = "<marc:datafield tag=\"" . xml_escape($tag) . "\" ind1=\"" . xml_escape($ind1) . "\" ind2=\"" . xml_escape($ind2) . "\">";
    
    while (@subfields) {
        my ($n,$v) = splice(@subfields,0,2);
        $buffer .= "<marc:subfield code=\"" . xml_escape($n) . "\">" . xml_escape($v) . "</marc:subfield>";
    }

    $buffer .= "</marc:datafield>";

    $buffer;
}

sub marc_footer {
    "</marc:record>";
}

sub xml_escape {
    local $_ = $_[0];
    s/&/\&amp;/g;
    s/</\&lt;/g;
    s/>/\&gt;/g;
    s/'/\&apos;/g;
    s/"/\&quot;/g;
    $_;
}

=head1 NAME

Catmandu::Fix::marc_xml - transform a Catmandu MARC record into MARCXML

=head1 SYNOPSIS
   
   # Transforms the 'record' key into an MARCXML string
   marc_xml('record');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
