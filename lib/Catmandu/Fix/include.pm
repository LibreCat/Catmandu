package Catmandu::Fix::include;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);
has _fixer => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        Catmandu::Fix->new(
            fixes => [ $_[0]->path() ]
        );
    }
);

sub fix {
	my ($self,$data) = @_;
    $self->_fixer()->fix($data);
}

=head1 NAME

Catmandu::Fix::include - include fixes from another file

=head1 SYNOPSIS

    include('/path/to/myfixes.txt')

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
