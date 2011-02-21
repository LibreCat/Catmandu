package Catmandu::Fixer::Fix::substring;
# VERSION
use Moose;
use Catmandu::Fixer::Util qw(path_and_field path_values);

extends qw(Catmandu::Fixer::Fix);

has [qw(path field offset length)] => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $field,$offset,$length) = @_;
    (my $path, $field) = path_and_field($field);
    { path      => $path,
      field     => $field,
      offset    => $offset,
      length    => $length };
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

    my $offset = $self->offset;
    my $length = $self->length;

    if (ref $val eq 'ARRAY') {
        [ map { substr($_,$offset,$length) } @$val ];
    } else {
        substr($val,$offset,$length);
    }
}

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Fixer::Util;

1;

