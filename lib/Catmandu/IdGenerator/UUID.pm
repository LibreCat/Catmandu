package Catmandu::IdGenerator::UUID;

use Catmandu::Sane;

our $VERSION = '1.2004';

use Data::UUID::MT;
use Moo;
use namespace::clean;

with 'Catmandu::IdGenerator';

has _uuid => (is => 'lazy', builder => '_build_uuid');

sub _build_uuid {Data::UUID::MT->new(version => 4)}

sub generate {
    $_[0]->_uuid->create_string;
}

1;

__END__

=pod

=head1 NAME

Catmandu::IdGenerator::UUID - Generator of UUID identifiers

=head1 SYNOPSIS

    use Catmandu::IdGenerator::UUID;

    my $x = Catmandu::IdGenerator::UUID->new;

    for (1..100) {
       printf "id: %s\n" , $x->generate;
    }

=head1 DESCRIPTION

This L<Catmandu::IdGenerator> generates identifiers based on the Universally
Unique Identifier (UUID) v4 standard. A UUID string is a 128 bit number
represented by lowercase hexadecimal digits such as
C<de305d54-75b4-431b-adb2-eb6b9e546014>.

=cut
