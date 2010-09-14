package Catmandu::Indexer::Converter;

use 5.010;
use Mouse;

sub convert {
  my ($self,$ref) = @_ ;

  confess "Reference is not a Perl hash ref" unless ref($ref) eq 'HASH';

  my $converted = {};

  foreach my $key (keys %$ref) {
    $converted->{$key} = $self->flatten($ref->{$key});
  }
 
  $converted;
}

sub flatten {
  my ($self,$value) = @_;

  my $ret;
  given(ref $value) {
    when('ARRAY') {
      $ret = join(" ", map($self->flatten($_),@$value));
    }
    when('HASH') {
      my @values = map { $value->{$_} } sort keys %$value;
      $ret = join(" ", map($self->flatten($_), @values));
    }
    default {
      $ret = "$value";
    }
  }

  $ret;
}

1;

__END__

=head1 NAME

 Catmandu::Indexer::Converter - Simple flattener for Perl hashes that can
 be used to index bibliographica data

=head1 SYNOPSIS

 my $converter = Catmandu::Indexer::Converter->new;

 my $obj = {
            title   => 'ABC' ,
            authors => [
                { first => 'James' , last => 'Brown' } ,
                { first => 'Miles' , last => 'Davis' }
            ]
          };

 my $doc = $converter->convert($obj);

 $doc = { title => 'ABC' , authors => 'James Brown Miles Davis' };
 
=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
