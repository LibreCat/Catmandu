package Catmandu::Indexer::Mock;

use 5.010;
use Mouse;

sub BUILD {
  my $self;

  # Do some initalization...
}

sub delete {
  my ($self,%args) = @_;
  
  # Doing deletes..boom..and its gone
  
  1; 
}

sub index_obj {
  my ($self, $obj) = @_;

  # implement here your indexation

  1;
}

sub index {
  my ($self, $obj, $converter) = @_;

  my $count = 0;
  given (ref $obj) {
    when('ARRAY') {
      foreach (@$obj) {
        $count += $self->index_obj($_, $converter);
      }
    } 
    when('HASH') {
      $count += $self->index_obj($obj, $converter);
    }
    when(blessed($obj) && $obj->can('each')) {
      $obj->each(sub {
        $count += $self->index_obj(shift, $converter);
      });  
    }
    default {
        confess "Can't index";
    }
  }

  $count;
}

sub done {
   1;
}

1;

__END__

=head1 NAME

 Catmandu::Indexer::Mock - Mock indexer doesn't do anything actually

=head1 SYNOPSIS

 my $indexer = Catmandu::Indexer::Mock->open();

 $indexer->delete(id => '234324');
 
 $indexer->index({ id => 1, name => 'Mary'});

 $indexer->done;

=head1 METHODS

=over 4

=item new()

Created a new Mock instance.

=item delete(%args).

Simulates a deletion from an index.

=item index($obj [,$converter])

=item index($array_ref [,$converter])

=item index($something_that_can_do_each [,$converter])

Simulates a adding to an index.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
