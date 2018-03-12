package Catmandu::Fix::Builder;

use Catmandu::Sane;

our $VERSION = '1.0606';

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
