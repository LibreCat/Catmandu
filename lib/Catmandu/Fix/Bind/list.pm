package Catmandu::Fix::Bind::list;

use Catmandu::Sane;

our $VERSION = '1.0301';

use Moo;
use Clone ();
use Catmandu::Util;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Bind';

has path => (fix_opt => 1);
has var  => (fix_opt => 1);

has _root_ => (is => 'rw');
has flag => (is => 'rw', default => sub {0});

sub zero {
    my ($self) = @_;
    [];
}

sub unit {
    my ($self, $data) = @_;

    $self->_root_($data);

    # Set a flag so that all the bind fixes are only run once...
    $self->flag(0);

    defined $self->path ? Catmandu::Util::data_at($self->path, $data) : $data;
}

sub bind {
    my ($self, $mvar, $func, $name, $fixer) = @_;

    if (Catmandu::Util::is_hash_ref($mvar)) {

        # Ignore all specialized processing when not an array
        $mvar = $func->($mvar);
    }
    elsif (Catmandu::Util::is_array_ref($mvar)) {
        return $mvar if $self->flag;

        # Run only these fixes once: no need for do identity() ... end
        $self->flag(1);

        my $idx = 0;

        [
            map {
                my $scope;
                my $has_default_context_variable = 0;

                # Switch context to the variable set by the user
                if ($self->var) {
                    $scope = $self->_root_;
                    $scope->{$self->var} = $_;
                }
                elsif (!ref($_)) {
                    $scope                        = [$_];
                    $has_default_context_variable = 1;
                }
                else {
                    $scope = $_;
                }

                # Run /all/ the fixes on the scope
                my $res = $fixer->fix($scope);

                # Check for rejects()
                if (defined $res) {
                    if ($self->var) {
                        $mvar->[$idx] = $scope->{$self->var};
                    }
                    elsif ($has_default_context_variable) {
                        $mvar->[$idx] = $res->[0];
                    }
                    $idx++;
                }
                else {
                    splice(@$mvar, $idx, 1);
                }

                delete $scope->{$self->var} if $self->var;
            } @$mvar
        ];
    }
    else {
        return $self->zero;
    }
}

# Flatten an array: [ [A] , [A] , [A] ] -> [ A, A, A ]
sub plus {
    my ($self, $prev, $next) = @_;

    Catmandu::Util::is_array_ref($next) ? [$prev, @$next] : [$prev, $next];
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Bind::list - a binder that computes Fix-es for every element in a list

=head1 SYNOPSIS

     # Create an array:
     #  demo:
     #    - red
     #    - green
     #    - yellow

     # Add a foo field to every item in the demo list, by default all 
     # fixes will be in context of the iterated path. If the context
     # is a list, then '.' will be the path of the temporary context
     # variable
     do list(path:demo)
        if all_equal(.,green)
            upcase(.)
        end
     end

     # This will result:
     #  demo:
     #    - red
     #    - GREEN
     #    - yellow

     # Loop over the list but store the values in a temporary 'c' variable
     # Use this c variable to copy the list to the root 'xyz' path
     do list(path:demo,var:c)
        copy_field(c,xyz.$append)
     end

     # This will result:
     #  demo:
     #    - red
     #    - GREEN
     #    - yellow
     #  xyz:
     #    - red
     #    - GREEN
     #    - yellow

=head1 DESCRIPTION

The list binder will iterate over all the elements in a list and fixes the 
values in context of that list.

=head1 CONFIGURATION

=head2 path 

The path to a list in the data.

=head2 var

The loop variable to be iterated over. When used, a magic temporary field will 
be available in the root of the record containing the iterated data. 

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
