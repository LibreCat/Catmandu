package Catmandu::File;
# VERSION
use Moose::Role;
use MooseX::Types::IO qw(IO);

requires '_build_file';

has path => (
    is => 'ro',
    isa => 'Str',
);

has file => (
    is => 'ro',
    isa => IO,
    coerce => 1,
    required => 1,
    lazy => 1,
    builder => '_build_file',
    trigger => sub { my $self = shift; $self->_after_file_set(@_) },
);

sub _after_file_set { }

around BUILDARGS => sub {
    my $super = shift;
    my $class = shift;

    my $args = $class->$super(@_);

    if ($args->{path}) {
        $args->{file} = $args->{path};
    } elsif ($args->{file} and not ref $args->{file}) {
        $args->{path} = $args->{file};
    }

    $args;
};

no MooseX::Types::IO;
no Moose::Role;

1;

