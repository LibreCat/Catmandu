package Catmandu::Importer::Aleph;

use 5.010;

use Moose;
use Data::Dumper;
use File::Slurp qw(slurp);
use List::MoreUtils qw(natatime);

no strict "subs";

with 'Catmandu::Importer';

has map => (
    traits => ['Getopt'],
    is => 'rw',
    isa => IO,
    coerce => 1,
    documentation => "Path to the Aleph map definition file to use.",
);

sub each {
   my ($self, $callback) = @_;
   my $num = 0;

   my $fh  = $self->file;

   my $rec     = {};

   my $prev_id = undef;

   binmode $fh, ':utf8';

   my $mapper  = $self->mapper( $self->load_map || $self->default_map );

   while(<$fh>) {
     chomp;
     my ($sysid,@data)  = &parse_line($_);
 
     if (defined $prev_id && $prev_id != $sysid) {
        if (defined $callback) {
            &$callback( $mapper->($rec) ); 
        }

        $rec = {};
     }

     $rec->{id} = $sysid;
     push @{$rec->{data}}, [@data];

     $prev_id = $sysid;
   }

   if (defined $callback) {
      &$callback( $mapper->($rec) ); 
   }

   return $num;
}

# Load a mapping file to map MARC fields to stored fields
# E.g. the input can be
#
#  245       title
#  540+a     rights
#  852+j     relation
#  100+ac    author
#  260-x     publisher
#
sub load_map {
    my $self = shift;

    return undef unless $self->map;

    my $map = [];

    foreach my $line (split /\n/, slurp($self->map)) {
        my ($path, $key) = split /\s+/, $line;
        push (@$map , [ $path => $key ]);
    }

    $map;
}

# Default mapping for Dublin Core-ish kind of records
sub default_map {
    my $self = shift;

    [
      '245'   => 'title' ,
      '260'   => 'title' ,
      '300'   => 'description' ,
      '100'   => 'creator' ,
      '700'   => 'creator' ,
      '260'   => 'publisher' ,
      '662'   => 'subject' ,
      '690'   => 'subject' ,
      '540+a' => 'rights' ,
      '852+j' => 'relation' ,
      '920'   => 'type' ,
    ]
}

# Transform MARC records into a hash of fields using a mapping file
# Usage:
#      
#   my $mapper = $self->mapper($map);
#   my $hash   = $mapper->($rec);
#
sub mapper {
    my ($self,$map) = @_;

    my $dc = {};
   

    my $eval =<<EOF;
sub {
   my \$rec = shift;

   my \$dc = {};

   \$dc->{identifier} = [ "rug01:" . \$rec->{id} ];
EOF

    while (@$map) {
        my ($key,$value) = splice(@$map, 0, 2);

        if ($key =~ /^(\w{3})(\+(\S+))?(\-(\S+))?/) {
            my $field    = $1;
            my $includes = $3 ? ", includes => '$3'" : "";
            my $excludes = $5 ? ", excludes => '$5'" : "";

            $eval .= "   push(\@{\$dc->{$value}} , \&field(\$rec, '$field' $includes $excludes) );\n";
        }
        else {
            warn "syntax error in map '$key' -> '$value'";
        }
    }

    $eval .=<<EOF;

    \&clean_empty(\$dc);
}
EOF

   eval $eval;
}

sub clean_empty {
    my $rec = shift;
    my $out = {};

    foreach my $key (keys %$rec) {
        my $val = $rec->{$key};

        $out->{$key} = $val if defined $val && @$val > 0; 
    }

    $out;
}


sub field {
    my ($rec,$field, %opts) = @_;

    my @fields = grep { $_->[0] =~ /$field/ } @{$rec->{data}};

    my @out = ();

    foreach (@fields) {
        my $len    = @$_;
        my @data   = @$_[4 .. $len -1 ];
        my @values = ();

        my $it = natatime 2, @data;

        INNER: while (my @v = $it->() ) {
            next INNER if defined $opts{includes} && $v[0] !~ /$opts{includes}/;
            next INNER if defined $opts{excludes} && $v[0] =~ /$opts{excludes}/;

            push (@values, $v[1]);
        }

        my $str = join(" ",@values);
        $str =~ s/(^\s+|\s+$)//;

        push @out , $str;
    }

    @out; 
}

sub parse_line {
    my ($line) = @_;
    my $sysid = substr($line,0,9);
    my $tag   = substr($line,10,3);
    my $ind1  = substr($line,13,1);
    my $ind2  = substr($line,14,1);
    my $char  = substr($line,16,1);
    my $data  = substr($line,18);

    my @parts = ('_' , split(/\$\$(.)/, $data) );

    ( $sysid , $tag , $ind1 , $ind2 , $char , @parts );
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;
