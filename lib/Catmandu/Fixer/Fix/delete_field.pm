package Catmandu::Fixer::Fix::delete_field;
# VERSION
use Moose;
use Catmandu::Fixer::Util qw(path_and_field path_values);

extends qw(Catmandu::Fixer::Fix);

has [qw(path field)] => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $path) = @_;
    ($path, my $field) = path_and_field($path);
    { path  => $path,
      field => $field, };
};

sub apply_fix {
    my ($self, $obj) = @_;

    my $field = $self->field;

    if (my $path = $self->path) {
        for my $o ($path->values($obj)) {
            delete $o->{$field};
        }
    } else {
        delete $obj->{$field};
    }

    $obj;
};

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Fixer::Util;

1;

