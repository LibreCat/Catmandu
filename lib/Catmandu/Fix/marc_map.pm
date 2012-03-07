package Catmandu::Fix::marc_map;

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Data::Dumper;
use Moo;

has path  => (is => 'ro', required => 1);
has key   => (is => 'ro', required => 1);
has mpath => (is => 'ro', required => 1);
has opts  => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $mpath, $path, %opts) = @_;
    my ($p,$key) = parse_data_path($path) if defined $path && length $path;
    $orig->($class, path => $p, key => $key, mpath => $mpath, opts => \%opts);
};

sub fix {
    my ($self, $data) = @_;

    my $path  = $self->path;
    my $key   = $self->key;
    my $mpath = $self->mpath;
    my $opts  = $self->opts || {};
    $opts->{-join} = '' unless $opts->{-join};
    
    my $marc_pointer = $opts->{-record} || 'record';
    my $marc  = $data->{$marc_pointer}; 

    my $fields = &marc_field($marc,$mpath);

    my $match = [ grep ref, data_at($path, $data, key => $key, create => 1)]->[0];

    for my $field (@$fields) {
       my $field_value = &marc_subfield($field,$mpath);

       next if &is_empty($field_value);

       $field_value = [$opts->{-value}] if defined $opts->{-value};
       $field_value = join $opts->{-join} , @$field_value if defined $opts->{-join};
       $field_value = &create_path($opts->{-in},$field_value) if defined $opts->{-in};
       $field_value = &path_substr($mpath,$field_value) unless index($mpath,'/') == -1;

       if (is_array_ref($match)) {
          if (is_integer($key)) {
             $match->[$key] = $field_value;
          }
          else {
             push @{$match}, $field_value;
          }
       }
       else {
          if (exists $match->{$key}) {
             $match->{$key} .= $opts->{-join} . $field_value;
          }
          else {
             $match->{$key} = $field_value;
          }
       } 
    }

    $data;
}

sub is_empty {
    my ($ref) = shift;
    for (@$ref) {
      return 0 if defined $_;
    }
    return 1;
}

sub path_substr {
    my ($path,$value) = @_;
    return $value unless is_string($value);
    if ($path =~ /\/(\d+)(-(\d+))?/) {
      my $from = $1;
      my $to   = defined $3 ? $3-$from+1 : 0;
      return substr($value,$from,$to);
    }
    return $value;
}

sub create_path {
    my ($path, $value) = @_;
    my ($p,$key,$guard) = parse_data_path($path);
    my $leaf  = {};
    my $match = [ grep ref, data_at($p, $leaf, key => $key, guard => $guard, create => 1) ]->[0];
    $match->{$key} = $value;
    $leaf;
}

# Parse a marc_path into parts
#  245[1,2]abd  - field=245, ind1=1, ind2=2, subfields = a,d,d
#  008/33-35    - field=008 from index 33 to 35
sub parse_marc_path {
    my $path = shift;

    if ($path =~ /(\S{3})(\[(.)?,?(.)?\])?([_a-z0-9]+)?(\/(\d+)(-(\d+))?)?/) {
        my $field    = $1;
        my $ind1     = $3;
        my $ind2     = $4;
        my $subfield = $5 ? "[$5]" : "[a-z0-9_]";
        my $from     = $7;
        my $to       = $9;
        return { field => $field , ind1 => $ind1 , ind2 => $ind2 , subfield => $subfield , from => $from , to => $to };
    }
    else {
        return {};
    }
}

# Given an Catmandu::Importer::MARC item return all the field value
# that match the MARC path $path
# Usage: marc_value($data,'245[a]',-join=>' ');
sub marc_value {
    my ($marc_item,$path,$opts) = @_;
    my $marc_path = &parse_marc_path($path);

    my $join    = $opts->{-join} || ' ';
    my @results = ();

    my $subfields = &marc_field($marc_item,$marc_path->{field});

    for my $arr (@$subfields) {
      my $res;
      my $matched = &marc_subfield($arr,$marc_path->{subfield});      
      if (@$matched) {
         $res = join $join , @$matched;
      }
      else {
         $res = undef;
      }
      push(@results, $res);
    }

    return \@results;
}

# Given a Catmandu::Importer::MARC item return for each matching field the
# array of subfields
# Usage: marc_field($data,'245');
sub marc_field {
    my ($marc_item,$path) = @_;
    my $marc_path = &parse_marc_path($path);
    my @results = ();

    my $field = $marc_path->{field};
    $field =~ s/\*/./g;

    for (@$marc_item) {
      my ($tag,$ind1,$ind2,@subfields) = @$_;
      unless (index($tag,0) == 0 || $tag eq 'LDR') {
        splice(@subfields,0,2);
      }
      push(@results,\@subfields) if $tag =~ /$field/;
    }

    return \@results;
}

# Given a subarray of Catmandu::Importer::MARC subfields return all
# the subfields that match the $subfield regex
# Usage: marc_subfield($subfields,'[a]');
sub marc_subfield {
    my ($subfields,$path) = @_;
    my $marc_path = &parse_marc_path($path);
    my $regex = $marc_path->{subfield};

    my @results = ();

    for (my $i = 0 ; $i < @$subfields ; $i += 2) {
      my $code = $subfields->[$i];
      my $val  = $subfields->[$i+1];
      push(@results,$val) if $code =~ /$regex/;   
    }
   
    return \@results;
}

1;

=head1 NAME

Catmandu::Fix::marc_map - copy marc values of one field to a new field

=head1 SYNOPSIS

    # Copy all 245 subfields into the my.title hash
    marc_map('245','my.title');

    # Copy the 245-$a$b$c subfields into the my.title hash
    marc_map('245abc','my.title');

    # Copy the 100 subfields into the my.authors array
    marc_map('100','my.authors.$append');
    
    # Add the 710 subfields into the my.authors array
    marc_map('710','my.authors.$append');

    # Copy the 600-$x subfields into the my.subjects array while packing each into a genre.text hash
    marc_map('600x','my.subjects.$append', -in => 'genre.text');

    # Copy the 008 characters 35-35 into the my.language hash
    marc_map('008_/35-35','my.language');

    # Copy all the 600 fields into a my.stringy hash joining them by '; '
    marc_map('600','my.stringy', -join => '; ');

    # When 024 field exists create the my.has024 hash with value 'found'
    marc_map('024','my.has024', -value => 'found');

    # Do the same examples now with the marc fields in 'record2'
    marc_map('245','my.title', -record => 'record2');

=cut
