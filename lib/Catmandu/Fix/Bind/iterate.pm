package Catmandu::Fix::Bind::iterate;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Moo;
use Catmandu::Util;
use Catmandu::Fix::Has;
use namespace::clean;

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

has start => (fix_opt => 1);
has end   => (fix_opt => 1);
has step  => (fix_opt => 1);
has var   => (fix_opt => 1);

sub unit {
    my ($self, $data) = @_;
    $data;
}

sub bind {
    my ($self, $mvar, $func, $name, $fixer) = @_;

    my $start = $self->start;
    my $end   = $self->end;
    my $step  = $self->step // 1;
    my $var   = $self->var;

    if (   Catmandu::Util::is_number($start)
        && Catmandu::Util::is_number($end)
        && Catmandu::Util::is_number($step))
    {
        for (my $i = $start; $i <= $end; $i = $i + $step) {
            $mvar->{$var} = $i if defined($var);
            $mvar = $func->($mvar);
        }
    }

    delete $mvar->{$var} if defined($var);

    return $mvar;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Bind::iterate - a binder iterates fixes in a loop

=head1 SYNOPSIS


     # Create:
     #   numbers = [1,2,3,4,5,6,7,8,9,10]
     do iterate(start:1, end: 10, step: 1, var: i)
        copy_field(i,numbers.$append)
     end

=head1 DESCRIPTION

The list binder will iterate over all the elements in a list and fixes the
values in context of that list.

=head1 CONFIGURATION

=head2 start

Start value of the iterator.

=head2 end

End value of the iterator.

=head2 step

Increase the interator with this value for every step.

=head3 var

Optional variable holding the value of the current step

=head1 SEE ALSO

L<Catmandu::Fix::Bind> ,
L<Catmandu::Fix::list> ,
L<Catmandu::Fix::with> ,

=cut
