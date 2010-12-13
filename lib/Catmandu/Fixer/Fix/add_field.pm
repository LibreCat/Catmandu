package Catmandu::Fixer::Fix::add_field;

use namespace::autoclean;
use Catmandu::Util qw(quoted unquote);
use Catmandu::Types qw(JSONPath);
use Moose;

extends qw(Catmandu::Fixer::Fix);

has jpath => (is => 'ro', isa => JSONPath, coerce => 1, required => 1);
has field => (is => 'ro', required => 1);
has value => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $field, $value) = @_;
    $field =~ /(.+)\.(\w+)$/ or confess "Invalid path";
    my $jpath = $1;
    $field = $2;
    { jpath => $jpath,
      field => $field,
      value => $value, };
};

augment apply_fix => sub {
    my ($self, $obj) = @_;
    if ($self->jpath->to_string eq '$') { #TODO JSON::Path doesn't seem to handle root references correctly
        $obj->{$self->field} = unquote($self->value);
    } else {
        foreach my $o ($self->jpath->values($obj)) {
            $o->{$self->field} = unquote($self->value);
        }
    }
    inner;
    $obj;
};

1;

