package Catmandu::Fixer::Fix::lookup;
# Replace a value using a tab-delimited lookup table
# VERSION
use Moose;
use File::Slurp;
use Catmandu::Fixer::Util qw(path_and_field path_values);

extends qw(Catmandu::Fixer::Fix);

has [qw(path field config)] => (is => 'ro');

has '_map' => (
	is => 'ro' ,
	isa => 'HashRef' ,
	default => sub { {} }
);

around BUILDARGS => sub {
    my ($orig, $class, $field, $config) = @_;
    (my $path, $field) = path_and_field($field);
    { path      => $path,
      field     => $field,
      config    => $config };
};

sub map {
    my $self   = shift;
    my $config = shift;
    
    return $self->_map->{$config} if defined $self->_map->{$config};

    foreach (read_file($config)) {
	chomp;
	my ($n,$v) = split(/\t/,$_,2);	
	$self->_map->{$config}->{$n} = $v;
    }

    return $self->_map->{$config};
}

sub apply_fix {
    my ($self, $obj) = @_;

    my $field  = $self->field;
    my $config = $self->config;
    my $map    = $self->map($config);

    my $fixer = sub {
        my $val = shift ;
	$map->{$val} || $val;
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
