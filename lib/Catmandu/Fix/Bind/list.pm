package Catmandu::Fix::Bind::list;

use Moo;
use Data::Dumper;
use Clone ();
use Catmandu::Util;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Bind';

has path   => (fix_opt => 1);
has var    => (fix_opt => 1);

has _root_ => (is => 'rw');

sub zero {
    my ($self) = @_;
    [];
}

sub unit {
    my ($self,$data) = @_;

    $self->_root_($data);

    if (defined $self->path) {
        Catmandu::Util::data_at($self->path,$data);
    }
    elsif (Catmandu::Util::is_array_ref($data)) {
        $data;
    }
    else {
        [$data];
    }    
}

sub bind {
    my ($self,$mvar,$func,$name) = @_;

    if (Catmandu::Util::is_array_ref($mvar)) {
        [ map { 
            my $scope;
            if ($self->var) {
                $scope = $self->_root_;
                $scope->{$self->var} = Clone::clone($_);
            }
            else {
                $scope = $_;
            }
            
            my $res = $func->($scope);

            delete $res->{$self->var} if $self->var; 
          } 
          @$mvar 
         ];
    }
    else {
        return $self->zero;
    }
}

# Flatten an array: [ [A] , [A] , [A] ] -> [ A, A, A ]
sub plus {
    my ($self,$prev,$next) = @_;

    Catmandu::Util::is_array_ref($next) ? [ $prev, @$next ] : [ $prev, $next] ;
}

=head1 NAME

Catmandu::Fix::Bind::list - a binder that computes Fix-es for every element in a list

=head1 SYNOPSIS

     # Create an array:
     #  demo:
     #    - test: 1
     #    - test: 2
     add_field(demo.$append.test,1)
     add_field(demo.$append.test,2)

     # Add a foo field to every item in the demo list, by default all 
     # fixes will be in context of the iterated path
     do list(path:demo)
        add_field(foo,bar)
     end

     # Loop over the list but store the values in a temporary 'loop' variable
     # Use this loop variable to copy the list to the root 'xyz' path
     do list(path:demo,var:loop)
        copy_field(loop.test,xyz.$append)
     end

     # This will result:
     #  demo:
     #    - test: 1
     #    - test: 2
     #  xyz:
     #    - 1
     #    - 2

=head1 DESCRIPTION

The list binder will iterate over all the elements in a list and fixes the values in context of that list.

=head1 CONFIGURATION

=head2 path 

The path to a list in the data.

=head2 var

The loop variable to be iterated over. When used, a magic field will be available
in the root of the record containing iterated data.

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut

1;
