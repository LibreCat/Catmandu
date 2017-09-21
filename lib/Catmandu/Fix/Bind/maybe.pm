package Catmandu::Fix::Bind::maybe;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Moo;
use Scalar::Util qw(reftype);
use namespace::clean;

with 'Catmandu::Fix::Bind';

# Copied from hiratara's Data::Monad::Maybe
sub just {
    my ($self, @values) = @_;
    bless [@values], __PACKAGE__;
}

sub nothing {
    my ($self) = @_;
    bless \(my $d = undef), __PACKAGE__;
}

sub is_nothing {
    my ($self, $mvar) = @_;
    reftype $mvar ne 'ARRAY';
}

sub value {
    my ($self, $mvar) = @_;

    if ($self->is_nothing($mvar)) {
        {};
    }
    else {
        $mvar->[0];
    }
}

sub unit {
    my ($self, $data) = @_;
    $self->just($data);
}

sub bind {
    my ($self, $mvar, $func) = @_;

    if ($self->is_nothing($mvar)) {
        return $self->nothing;
    }

    my $res;

    eval {$res = $func->($self->value($mvar));};

    if ($@) {
        return $self->nothing;
    }

    if (defined $res) {
        return $self->just($res);
    }
    else {
        return $self->nothing;
    }
}

sub result {
    my ($self, $mvar) = @_;
    $self->value($mvar);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Bind::maybe - a binder that skips fixes if one returns undef or dies

=head1 SYNOPSIS

 do maybe()
    foo()
    return_undef() # rest will be ignored
    bar()
 end

=head1 DESCRIPTION

The maybe binder computes all the Fix function and ignores fixes that throw exceptions.

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
