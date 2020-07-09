package Catmandu::Fix::Builder;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Catmandu::Fix;
use Catmandu::Util qw(is_value require_package);
use Moo::Role;
use namespace::clean;

with 'Catmandu::Fix::Base';

has fixer => (is => 'lazy');

sub emit {
    my ($self, $fixer) = @_;
    my $data_var = $fixer->var;
    my $sub_var  = $fixer->capture($self->fixer);
    my $val      = $self->_emit_call($sub_var, $data_var);
    $self->_emit_assign($data_var, $val);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Builder - Base role for Catmandu fixes

=head1 DESCRIPTION

This role expects a C<_build_fixer> method that produces a coderef that
transforms the data.  Used in combination with L<Catmandu::Path>
implementations, data manipulations can be described in a relatively high-level
way. Most fixes shipped with Catmandu work this way and can be used as a
starting point to write your own fixes.

=head1 SYNOPSIS

    package Catmandu::Fix::my_fix;

    use Catmandu::Sane;
    use Moo;

    with 'Catmandu::Fix::Builder';

    sub _build_fixer {
        sub {
            my ($data) = @_;
            $data->{foo} = 'bar';
            $data;
        }
    }

=cut
