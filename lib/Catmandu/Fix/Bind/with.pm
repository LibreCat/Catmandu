package Catmandu::Fix::Bind::with;

use Moo;
use Data::Dumper;
use Catmandu::Util;
use Catmandu::ArrayIterator;

with 'Catmandu::Fix::Bind';

has path   => (is => 'ro');

sub zero {
    my ($self) = @_;
    [];
}

sub unit {
    my ($self,$data) = @_;

    my $ref;
    
    if (defined $self->path) {
        $ref = Catmandu::Util::data_at($self->path,$data);
    }
    else {
        $ref = $data;
    }

    return $ref;
}

sub bind {
    my ($self,$mvar,$func,$name,$fixer) = @_;

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

    do with(my.deep.field)
        add_field(style,funk)
    end

=head1 CONFIGURATION

=head2 path 

The path to a list in the data.

=head1 AUTHOR

Patrick Hochstenbach - L<Patrick.Hochstenbach@UGent.be>

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut

1;
