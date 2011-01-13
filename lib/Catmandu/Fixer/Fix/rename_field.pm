package Catmandu::Fixer::Fix::rename_field;
# VERSION
use Moose;
use Catmandu::Fixer::Util qw(path_and_field path_values);

extends qw(Catmandu::Fixer::Fix);

has [qw(path old_field new_field)] => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $old_field, $new_field) = @_;
    (my $path, $old_field) = path_and_field($old_field);
    { path      => $path,
      old_field => $old_field,
      new_field => $new_field, };
};

sub apply_fix {
    my ($self, $obj) = @_;

    my $old_field = $self->old_field;
    my $new_field = $self->new_field;

    if (my $path = $self->path) {
        for my $o ($path->values($obj)) {
            $o->{$new_field} = delete $o->{$old_field};
        }
    } else {
        $obj->{$new_field} = delete $obj->{$old_field};
    }

    $obj;
};

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Fixer::Util;

1;

