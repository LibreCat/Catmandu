package Catmandu::Fix::Bind::maybe;

use Moo;
use Data::Dumper;
use Scalar::Util qw/reftype/;

with 'Catmandu::Fix::Bind';

# Copied from hiratara's Data::Monad::Maybe
sub just {
	my ($self,@values) = @_;
	bless [@values] , __PACKAGE__;
}

sub nothing {
	my ($self) = @_;
	bless \(my $d = undef), __PACKAGE__;
}

sub is_nothing { reftype $_[0] ne 'ARRAY'  }

sub value {
    if (is_nothing($_[0])) {
        {};
    } else {
        $_[0]->[0];
    }
}
# ---

sub unit {
	my ($self,$data) = @_;
	$self->just($data);
}

sub bind {
	my ($self,$mvar,$func) = @_;

	if (is_nothing($mvar)) {
		return $self->nothing;
	}

	my $res;

	eval { 

		$res = $func->(value($mvar))
	};
	if ($@ && ref $@ eq 'Catmandu::Fix::Reject') {
		die $@;
	}
	else {
		return $self->nothing;
	}  
	
	if (defined $res) {
		return $self->just($res);
	}
	else {
		return $self->nothing;
	}
}

=head1 NAME

Catmandu::Fix::Bind::maybe - a binder that skips fixes is one returns undef

=head1 SYNOPSIS

 do maybe()
	foo()
	return_undef() # rest will be ignored
	bar()
 end

=head1 DESCRIPTION

The maybe binder computes all the Fix function and ignores fixes that throw exceptions.

=head1 AUTHOR

Patrick Hochstenbach <Patrick . Hochstenbach @ UGent . be >

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut

1;