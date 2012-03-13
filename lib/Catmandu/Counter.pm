package Catmandu::Counter;

use Catmandu::Sane;
use Moo::Role;

has count => (is => 'ro', init_arg => undef, default => sub { 0 });

sub inc_count {
    ++$_[0]->{count};
}

sub dec_count {
    my $self = $_[0]; $self->{count} ? --$self->{count} : 0;
}

sub reset_count {
    $_[0]->{count} = 0;
}

1;
