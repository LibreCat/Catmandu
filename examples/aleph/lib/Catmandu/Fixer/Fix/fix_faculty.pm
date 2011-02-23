package Catmandu::Fixer::Fix::fix_faculty;
# VERSION
use Moose;
use Catmandu::Fixer::Util qw(path_and_field path_values);

extends qw(Catmandu::Fixer::Fix);

has [qw(path field)] => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $field) = @_;
    (my $path, $field) = path_and_field($field);
    { path      => $path,
      field     => $field };
};

sub apply_fix {
    my ($self, $obj) = @_;

    my $field  = $self->field;

    my $fixer = sub {
        my $val = shift || '';

        my %map = (
            'A'   => 'LA',
            'B'   => 'UB',
            'C'   => 'CD',
            'D'   => 'DI',
            'E'   => 'EB',
            'F'   => 'FW',
            'GUS' => 'GUS',
            'G'   => 'GE',
            'H'   => 'LW',
            'L'   => 'LW',
            'PS'  => 'PS',
            'PP'  => 'PP',
            'R'   => 'RE',
            'T'   => 'TW',
            'V'   => 'VL',
            'W'   => 'WE',
        );

        foreach my $k (keys %map) {
            return $map{$k} if (index($val,$k) == 0);
        }

        'UNKNOWN';
    };

    if (my $path = $self->path) {
        for my $o ($path->values($obj)) {
            $o->{$field} = $self->_fixme($o->{$field}, $fixer);
        }
    } else {
        $obj->{$field} = $self->_fixme($obj->{$field}, $fixer);
    }

    $obj;
};

sub _fixme {
    my ($self,$val, $callback) = @_;

    if (ref $val eq 'ARRAY') {
        [ map { $callback->($_)  } @$val ];
    } else {
        $callback->($val);
    }
}

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Fixer::Util;

1;

