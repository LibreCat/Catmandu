package Catmandu::Fixer::Fix::delete_field;

use namespace::autoclean;
use Catmandu::Types qw(JSONPath);
use Moose;

extends qw(Catmandu::Fixer::Fix);

has jpath => (is => 'ro', isa => JSONPath, coerce => 1, required => 1);
has field => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $field, $value) = @_;
    $field =~ m/(.+)\.(\w+)$/ or confess "Invalid path";
    my $jpath = $1;
    $field = $2;
    { jpath => $jpath,
      field => $field, };
};

augment apply_fix => sub {
    my ($self, $obj) = @_;
    if ($self->jpath->to_string eq '$') { #TODO JSON::Path doesn't seem to handle root references correctly
        delete $obj->{$self->field};
    } else {
        foreach my $o ($self->jpath->values($obj)) {
            delete $o->{$self->field};
        }
    }
    inner;
    $obj;
};

1;

