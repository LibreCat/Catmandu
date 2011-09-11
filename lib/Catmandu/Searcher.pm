package Catmandu::Searcher;
use Catmandu::Sane;
use parent qw(Catmandu::Iterable);
use Catmandu::Object total_hits => 'r', hits => 'r';
use Catmandu::Util qw(opts);

sub _build_args {
    my ($self, $index, $q, @opts) = @_;
    { index => $index,
      q     => $q,
      opts  => opts(@opts), };
}

sub _build {
    my ($self, $args) = @_;

    my $index = $args->{index};
    my $q     = $args->{q};
    my $opts  = $args->{opts};

    my $res = $index->search($q, %$opts);

    $self->{hits} = $$res->hits;
    $self->{total_hits} = $res->total_hits;
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
