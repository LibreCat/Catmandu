package Catmandu::IdGenerator::UUID;

use Catmandu::Sane;

our $VERSION = '1.2013';

use UUID::Tiny qw(:std);
use Moo;
use namespace::clean;

with 'Catmandu::IdGenerator';

sub generate {
    create_uuid_as_string(UUID_V1);
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
Unique Identifier (UUID) v1 standard. A UUID string is a 128 bit number
represented by lowercase hexadecimal digits such as
C<de305d54-75b4-431b-adb2-eb6b9e546014>.

=cut
