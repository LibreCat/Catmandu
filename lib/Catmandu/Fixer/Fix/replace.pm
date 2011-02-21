package Catmandu::Fixer::Fix::replace;
# VERSION
use Moose;
use Catmandu::Fixer::Util qw(path_and_field path_values);

extends qw(Catmandu::Fixer::Fix);

has [qw(path field search replace)] => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $field, $search, $replace) = @_;
    (my $path, $field) = path_and_field($field);
    { path      => $path,
      field     => $field,
      search    => $search,
      replace   => $replace };
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

    my $search  = $self->search;
    my $replace = $self->replace;

    if (ref $val eq 'ARRAY') {
        [ map { $_ =~ s/$search/$replace/g; $_ } @$val ];
    } else {
        $val =~ s/$search/$replace/g;
        $val;
    }
}

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Fixer::Util;

1;

