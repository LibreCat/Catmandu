package Catmandu::Fixer::Fix::add_field;
# VERSION
use Moose;
use Catmandu::Fixer::Util -all;

extends qw(Catmandu::Fixer::Fix);

has [qw(path field value)] => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $field, $value) = @_;
    (my $path, $field) = path_and_field($field);
    { path  => $path,
      field => $field,
      value => $value, };
};

sub apply_fix {
    my ($self, $obj) = @_;

    my $field = $self->field;

    my @vals = path_values($obj, $self->value);

    if (my $path = $self->path) {
        my @objs = $path->values($obj);
        if (@objs == @vals) {
            for my $i (0..@objs-1) {
                $objs[$i]->{$field} = $vals[$i];
            }
        } else {
            for my $o (@objs) {
                $o->{$field} = $vals[0];
            }
        }
    } else {
        $obj->{$field} = $vals[0];
    }

    $obj;
};

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Fixer::Util;

1;

