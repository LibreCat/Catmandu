package Catmandu::Id::Generator::Mock;
use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(:check);
use namespace::clean;

with 'Catmandu::Id::Generator';

has start => (
    is => 'ro',
    isa => sub { check_natural($_[0]); },
    lazy => 1,
    default => sub { 0; }
);
has _num => (
    is => 'rw',
    lazy => 1,
    builder => '_build_num'
);
sub _build_num {
    $_[0]->_num( $_[0]->start() );
}
sub generate {
    my $self = $_[0];
    my $old_num = $self->_num();
    $self->_num( $old_num + 1);
    $old_num;
}

1;
