package Catmandu::Hits;
use Catmandu::Sane;
use parent qw(Catmandu::Iterable);

sub new {
    bless $_[1], $_[0];
}

sub hits {
    $_[0]->{hits};
}

sub total_hits {
    $_[0]->{total_hits};
}

sub each {
    my ($self, $sub) = @_;
    my $hits = $self->hits;
    for my $hit (@$hits) {
        $sub->($hit);
    }
    scalar @$hits;
}

1;
