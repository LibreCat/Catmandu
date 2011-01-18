package Catmandu::Types;
# VERSION
use Hash::MultiValue;
use MooseX::Types::Moose qw(ArrayRef HashRef);
use MooseX::Types -declare => [qw(
    MultiValueHash
)];

class_type MultiValueHash, {class => 'Hash::MultiValue'};

coerce MultiValueHash,
    from ArrayRef,
        via { Hash::MultiValue->new(@$_) },
    from HashRef,
        via { Hash::MultiValue->from_mixed($_) };

no MooseX::Types::Moose;

1;

