package Catmandu::Fixer::Fix::join;
# VERSION
use Moose;
use Hash::Flatten qw(:all);
use Catmandu::Fixer::Util qw(path_and_field path_values);

extends qw(Catmandu::Fixer::Fix);

has [qw(path field expr)] => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $field, $expr) = @_;
    (my $path, $field) = path_and_field($field);
    { path      => $path,
      field     => $field,
      expr      => $expr };
};

sub apply_fix {
    my ($self, $obj) = @_;

    my $field  = $self->field;

    if (my $path = $self->path) {
        for my $o ($path->values($obj)) {
            $o->{$field} = $self->_fixme($o->{$field});
        }
    } else {
        $obj->{$field} = $self->_fixme($obj->{$field});
    }

    $obj;
};

sub _fixme {
    my ($self,$val) = @_;

    return undef unless $val;

    my $expr = $self->expr;

    if (!defined $val) {
	undef;
    }
    elsif (ref $val eq 'ARRAY') {
        join($expr, @$val)
    } 
    elsif (ref $val eq 'HASH') {
        join($expr, values(%$val));
    }
    else {
        $val
    }
}

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Fixer::Util;

1;

