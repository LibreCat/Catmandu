package Catmandu::Counter;

use Catmandu::Sane;
use Moo::Role;

has count => (is => 'ro', default => sub { 0 });

sub clear_count {
    $_[0]->{count} = 0;
}

sub inc_count {
    ++$_[0]->{count};
}

sub dec_count {
    my $self = $_[0];
    if ($self->{count}) {
        return --$self->{count};
    }
    0;
}

1;
