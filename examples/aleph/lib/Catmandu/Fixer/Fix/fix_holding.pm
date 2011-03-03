package Catmandu::Fixer::Fix::fix_holding;
# Calculate the holdings years 
# VERSION
use Moose;
use Parse::RecDescent;
use Catmandu::Fixer::Util qw(path_and_field path_values);

extends qw(Catmandu::Fixer::Fix);

has [qw(path field year_dest text_dest)] => (is => 'ro');
has 'parser'    => ( is => 'rw' );
has 'curryear'  => ( is => 'rw' );

around BUILDARGS => sub {
    my ($orig, $class, $field, $year_dest, $text_dest) = @_;
    (my $path, $field) = path_and_field($field);
    { path      => $path,
      field     => $field,
      year_dest => $year_dest,
      text_dest => $text_dest };
};

sub BUILD {
    my $self = shift;
    my $parser = Parse::RecDescent->new(q(
  startrule:	    item(s /;/) 
		    { $return = $item[1]; }

  item:	    	    holding '-' holding  
		    { $return = [ $item[1], $item[3] ]; }

		    |

		    holding '-'
		    { $return = [ $item[1] , 'NOW' ]; }

		    |

		    holding
		    { $return = [ $item[1] ]; }

		    |
		
	            /[^;]+/
		    { $return = [ ]; }

  holding : 	    '#' volume(?) '(' publication_year except_year(?) ')' issue(?) 
		    { $return = $item{publication_year} } 

		    |

	      	    volume(?) '(' publication_year ')'  issue(?)
		    { $return = $item{publication_year} } 

		    |

		    publication_year
		    { $return = $item{publication_year} }

  volume: 	    /\d+([-\/]\d+)?/

		    |

		    /[A-Za-z0-9:.]+/

  issue:            /\d+([-\/]\d+)?/
	
  except_year: 	    '/' /\d+/

  publication_year:  /(16|17|18|19|20)\d{2}/ 
));

   $self->parser($parser);
   $self->curryear([ localtime time]->[5] + 1900);
}

sub parse {
    my $self = shift;
    my $val  = shift;

    unless ($val) {
      return { years => [] , text => "" };
    }

    my $res = $self->parser->startrule(join "; ", @$val);

    # Collect all the parsed year hldings in an array of 'consecutive' years
    my %YEARS = ();
    foreach my $range (@$res) {
	next if (@$range == 0);	
        my $start = $range->[0];
	my $end   = $range->[1];
        $end = $start unless defined $end; 
        $end = $self->curryear if $end eq 'NOW';
	for ($start..$end) { $YEARS{$_} = 1}
    }

    my @years = sort { $a <=> $b } keys %YEARS;

    # Translate the array of 'consecutive' years into an array of year ranges
    my @ranges;
    my $start = 0;
    my $prev  = 0;

    foreach my $year (@years) {
	$start = $year unless $start;
        if ($prev && $year - $prev > 1) {
	  push(@ranges, $start eq $prev ? "$start" : "$start-$prev");
	  $start = $year;
 	}	
	$prev = $year;
    }

    push(@ranges, $start eq $prev ? "$start" : "$start-$prev") if $start; 
    
    { years => \@years , text => join("; ", @ranges) };
}

sub apply_fix {
    my ($self, $obj) = @_;

    my $field     = $self->field;
    my $year_dest = $self->year_dest;
    my $text_dest = $self->text_dest;

    my $fixer = sub { $self->parse(shift); };

    if (my $path = $self->path) {
        for my $o ($path->values($obj)) {
	    my $fix = $fixer->($o->{$field});
	    $o->{$year_dest} = $fix->{years};
	    $o->{$text_dest} = $fix->{text};
        }
    } else {
	my $fix = $fixer->($obj->{$field});
	$obj->{$year_dest} = $fix->{years};
	$obj->{$text_dest} = $fix->{text};
    }

    $obj;
};

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Fixer::Util;

1;
