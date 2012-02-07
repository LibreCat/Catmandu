package Catmandu::Fix::marc_in_json;

use Catmandu::Sane;
use Moo;

# Transform a raw MARC array into MARC-in-JSON
# See Ross Singer work at:
#  http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/
sub fix {
    my ($self, $data) = @_;

    my $mij = {}; 
    $mij->{_id} = $data->{_id}; 
 
    for my $f (@{$data->{record}}) { 
        my ($tag,$ind1,$ind2,@data) = @$f; 
        if ($tag eq 'LDR') { 
           $mij->{leader} = join "" , @data; 
        } 
        elsif ($tag =~ /^00|FMT/) { 
           shift @data; 
           push @{$mij->{fields}} , { $tag => join "" , @data }; 
        } 
        else { 
           my @subfields = (); 
           for (my $i = 2 ; $i < @data ; $i += 2) { 
             push @subfields , { $data[$i] => $data[$i+1] }; 
           }             
           push @{$mij->{fields}} , { $tag => { 
                                        subfields => \@subfields , 
                                        ind1 => $ind1 , 
                                        ind2 => $ind2 , 
                                    } 
                 }; 
        }  
    }

    $mij;
}

=head1 NAME

Catmandu::Fix::marc_in_json - transform a Catmandu MARC record into MARC-in-JSON

=head1 SYNOPSIS

   # Create a deeply nested key
   marc_in_json();

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
