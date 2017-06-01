package Catmandu::Store::MultiFiles;

use Catmandu::Sane;

our $VERSION = '1.0507';

use Catmandu::Util qw(:is);
use Hash::Util::FieldHash qw(fieldhash);
use Catmandu::Store::Multi::Bag;
use Moo;
use namespace::clean;

with 'Catmandu::FileStore';

has metadata => (
    is      => 'ro',
    coerce  => sub {
        my $store = $_[0];
        if (is_string($store)) {
            Catmandu->store($store);
        }
        else {
            warn 'here';
            $store;
        }
    }
);

has metadata_bag => (is => 'ro' , default => sub { 'data' });

has stores => (
    is      => 'ro',
    default => sub {[]},
    coerce  => sub {
        my $stores = $_[0];
        return [
            map {
                if (is_string($_)) {
                    Catmandu->store($_);
                }
                else {
                    $_;
                }
            } @$stores
        ];
    },
);

sub drop {
    my ($self) = @_;

    if ($self->metadata && $self->metadata->does('Catmandu::Droppable')) {
        $self->metadata->drop;
    }

    for my $store (@{$self->stores}) {
        $store->drop if $store->does('Catmandu::Droppable');
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::MultiFiles - A store that adds your files to multiple file stores
