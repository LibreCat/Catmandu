package Catmandu::IdGenerator::UUID;

use Catmandu::Sane;

our $VERSION = '1.00_01';

use Data::UUID;
use Moo;
use namespace::clean;

with 'Catmandu::IdGenerator';

has _uuid => (is => 'lazy', builder => '_build_uuid');

sub _build_uuid { Data::UUID->new }

sub generate {
    $_[0]->_uuid->create_str;
}

1;

__END__

=pod

=head1 NAME

Catmandu::IdGenerator::Mock - Generator of UUID identifiers

=head1 SYNOPSIS

    use Catmandu::IdGenerator::UUID;

    my $x = Catmandu::IdGenerator::Mock->new;

    for (1..100) {
       printf "id: %s\n" m $x->generate;
    }

=head1 SEE ALSO

L<Catmandu::IdGenerator>

=cut
