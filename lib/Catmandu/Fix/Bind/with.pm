package Catmandu::Fix::Bind::with;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use Clone ();
use Catmandu::Util;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

has path => (fix_opt => 1);

sub zero {
    my ($self) = @_;
    [];
}

sub unit {
    my ($self, $data) = @_;
    defined $self->path ? Catmandu::Util::data_at($self->path, $data) : $data;
}

sub bind {
    my ($self, $mvar, $code) = @_;

    if (Catmandu::Util::is_hash_ref($mvar)) {
        my $copy = Clone::clone($mvar);

        $copy = $code->($copy);

        if (ref($copy) eq 'reject') {

            #map { delete $mvar->{$_} } (keys %$mvar);
            %$mvar = ();
        }
        else {
            %$mvar = %$copy;
        }

        return $mvar;
    }
    elsif (Catmandu::Util::is_array_ref($mvar)) {
        my $idx = 0;
        for my $item (@$mvar) {
            $item = $code->($item);

            if (ref($item) eq 'reject') {
                splice(@$mvar, $idx, 1);
            }

            $idx++;
        }
        return $mvar;
    }
    else {
        return $self->zero;
    }
}

sub reject {
    my ($self, $var) = @_;
    return bless $var, 'reject' if ref($var);
    return bless \$var, 'reject';
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Bind::with - a binder that computes Fix-es in the context of a path

=head1 SYNOPSIS

     # Input data
     data:
     - name: patrick
     - name: nicolas

    # Fix
    do with(path:data)
        if all_match(name,nicolas)
            reject()
        end
    end

    # will produce
    data:
     - name: patrick


=head1 DESCRIPTION

The C<with> bind allows to run fixes in the scope of a path.

Given a deep nested data structure :

    my:
      deep:
        field:
           name: James Brown

these two fixes are equal:

    add_field(my.deep.field.style, funk)

    do with(path:my.deep.field)
        add_field(style,funk)
    end

=head1 CONFIGURATION

=head2 path

The path to a list in the data.

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
