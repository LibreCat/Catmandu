package Catmandu::IdGenerator::UUID;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Data::UUID;
use Moo;
use namespace::clean;

with 'Catmandu::IdGenerator';

has _uuid => (is => 'lazy', builder => '_build_uuid');

sub _build_uuid {Data::UUID->new}

sub generate {
    $_[0]->_uuid->create_str;
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
       printf "id: %s\n" m $x->generate;
    }

=head1 DESCRIPTION

This L<Catmandu::IdGenerator> generates identifiers based on the Universally
Unique Identifier (UUID) standard. A UUID is a 128 bit number represented by
lowercase hexadecimal digits such as C<de305d54-75b4-431b-adb2-eb6b9e546014>.

=cut
