package Catmandu::Importer::MARC;

use Catmandu::Sane;
use Moo;
use MARC::File::USMARC;
use MARC::File::MicroLIF;
use MARC::File::XML;

with 'Catmandu::Importer';

has type => (is => 'ro' , default => sub { 'USMARC' });

sub aleph_generator {
    my $self = shift;

    sub {
        state $fh = $self->fh;
        state $prev_id;
	    state $record = [];

        while(<$fh>) {
           chop;
           next unless (length $_ >= 18);

           my ($sysid,$s1,$tag,$ind1,$ind2,$s2,$char,$s3,$data) = unpack("A9A1A3A1A1A1A1A1U0A*",$_);
           utf8::decode($data);
           my @parts = ('_' , split(/\$\$(.)/, $data) );
           # If we have an empty subfield at the end, then we need to add a implicit empty value
           push(@parts,'') unless int(@parts) % 2 == 0;

           if (defined $prev_id && $prev_id != $sysid) {
		       my $result = { _id => $prev_id , record => [ @$record ] };
		       $record  = [[$tag, $ind1, $ind2, @parts]];
           	   $prev_id = $sysid;
		       return $result;
	       }

           push @$record, [$tag, $ind1, $ind2, @parts];

           $prev_id = $sysid;
        }

	    if (@$record > 0) {
    	   my $result = { _id => $prev_id , record => [ @$record ] };
	       $record = [];
	       return $result;
        }
	    else {
	       return;
 	    }
    };
}

sub marc_generator {
    my $self = shift;
	
    my $file;

    given($self->type) {
	    when ('USMARC') {
	        $file =  MARC::File::USMARC->in($self->fh); 
	    }
        when ('MicroLIF') {
            $file = MARC::File::MicroLIF->in($self->fh);
        }
        when ('XML') {
            $file = MARC::File::XML->in($self->fh);
        }
	    die "unknown";
    }

    sub {
        my $record = $file->next();
        return unless $record;

        my @result = ();

        push @result , [ 'LDR' , undef, undef, '_' , $record->leader ];

        for my $field ($record->fields()) {
            my $tag  = $field->tag;
            my $ind1 = $field->indicator(1);
            my $ind2 = $field->indicator(2);

            my @sf = ();

            for my $subfield ($field->subfields) {
                push @sf , @$subfield;
            }

            push @sf , '_' , $field->data if $field->is_control_field;

            push @result, [$tag,$ind1,$ind2,@sf];
        }

        my $sysid = $record->field('001') ? $record->field('001')->data : undef;
        return { _id => $sysid , record => \@result };
    };
}

sub generator {
    my ($self) = @_;
    my $type = $self->type;

    given ($type) {
	    when (/^USMARC|MicroLIF|XML$/) {
           return $self->marc_generator;
	    }
	    when ('ALEPHSEQ') {
           return $self->aleph_generator;
	    }
        die "need USMARC, MicroLIF, XML or ALEPHSEQ";
    }
}

=head1 NAME

Catmandu::Importer::MARC - Package that imports MARC data

=head1 SYNOPSIS

    use Catmandu::Importer::MARC;

    my $importer = Catmandu::Importer::MARC->new(file => "/foo/bar.marc", type=> "USMARC");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 MARC

The parsed MARC is a HASH containing two keys '_id' containing the 001 field (or the system
identifier of the record) and 'record' containing an ARRAY of ARRAYs for every field:

 {
  'record' => [
                      [
                        '001',
                        undef,
                        undef,
                        '_',
                        'fol05882032 '
                      ],
 		      [
                        245,
                        '1',
                        '0',
                        'a',
                        'Cross-platform Perl /',
                        'c',
                        'Eric F. Johnson.'
                      ],
	      ],
  '_id' => 'fol05882032'
 } 

=head1 METHODS

=head2 new(file => $filename,type=>$type)

Create a new MARC importer for $filename. Use STDIN when no filename is given. Type 
describes the sytax of the MARC records. Currently we support: USMARC, MicroLIF 
, XML and ALEPHSEQ.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::MARC methods are not idempotent: MARC feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
