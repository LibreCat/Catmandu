package Catmandu::Store::Multi;

use Catmandu::Sane;

our $VERSION = '1.0306';

use Catmandu::Util qw(:is);
use Catmandu::Store::Multi::Bag;
use Moo;
use namespace::clean;

with 'Catmandu::Store';

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
    for my $store (@{$self->store->stores}) {
        $store->drop;
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::Multi - A store that adds your data to multiple stores

=cut
