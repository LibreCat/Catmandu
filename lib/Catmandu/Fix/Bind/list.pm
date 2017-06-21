package Catmandu::Fix::Bind::list;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use Clone ();
use Catmandu::Util;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

has path => (fix_opt => 1);
has var  => (fix_opt => 1);

has root => (is => 'rw');

sub zero {
    my ($self) = @_;
    [];
}

sub unit {
    my ($self, $data) = @_;

    $self->root($data);

    defined $self->path ? Catmandu::Util::data_at($self->path, $data) : $data;
}

sub bind {
    my ($self, $mvar, $code) = @_;

    my $root = $self->root;
    my $var  = $self->var;

    if (Catmandu::Util::is_hash_ref($mvar)) {

        # Ignore all specialized processing when not an array
        $mvar = $code->($mvar);
        return $mvar;
    }
    elsif (Catmandu::Util::is_array_ref($mvar)) {
        for my $item (@$mvar) {
            if (defined $var) {
                $root->{$var} = $item;
                $root = $code->($root);
                delete $root->{$var};
            }
            else {
                $item = $code->($item);
            }
        }
        return $mvar;
    }
    else {
        return $self->zero;
    }
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
