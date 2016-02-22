package Catmandu::Fix::Bind::with;

use Catmandu::Sane;

our $VERSION = '1.00';

use Moo;
use Catmandu::Util;
use Catmandu::ArrayIterator;
use namespace::clean;

with 'Catmandu::Fix::Bind';

has path   => (is => 'ro');
has flag   => (is => 'rw');

sub zero {
    my ($self) = @_;
    [];
}

sub unit {
    my ($self,$data) = @_;

    my $ref;
    
    if (defined $self->path) {
        $ref = Catmandu::Util::data_at($self->path, $data);
    }
    else {
        $ref = $data;
    }

    # Set a flag so that all the bind fixes are only run once...
    $self->flag(0);

    return $ref;
}

sub bind {
    my ($self,$mvar,$func,$name,$fixer) = @_;

    # The fixer contains all the fixes no every separate fix.
    # Set a flag so that the fixes are only run once, creating an implicit do identity() ... end block

    return $mvar unless $self->flag == 0;

    my $ref;
    
    if (!defined $mvar) {
        $ref = $fixer->fix( $self->zero );
    }
    elsif (Catmandu::Util::is_array_ref($mvar)) {
        $ref = $fixer->fix( $mvar );
    }
    elsif (Catmandu::Util::is_hash_ref($mvar)) {
        $ref = $fixer->fix( $mvar );
    }
    else {
        $ref = $fixer->fix( $self->zero );
    }

    inline_copy($mvar,$ref);

    $self->flag(1);

    $mvar;
}

sub result {
    my ($self,$mvar) = @_;
    $self->flag(0);
    $mvar;
}

sub inline_copy {
    my ($old,$new) = @_;

    if (Catmandu::Util::is_array_ref($old)) {
        undef @{$old};
        for (@$new) {
            push @$old , $_;
        }
    }
    elsif (! defined $new) {
        undef %{$old};
    }
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
    do with(path => data)
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

    do with(path => my.deep.field)
        add_field(style,funk)
    end

=head1 CONFIGURATION

=head2 path 

The path to a list in the data.

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
