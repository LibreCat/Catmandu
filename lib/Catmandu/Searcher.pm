package Catmandu::Searcher;
use Catmandu::Sane;
use parent qw(Catmandu::Iterable);
use Catmandu::Object;
use Catmandu::Util qw(opts);

sub _build_args {
    my ($self, $index, $query, @opts) = @_;
    { index => $index, 
      query => $query,
      opts  => opts(@opts), };
}

sub each {
    my ($self, $sub) = @_;
    my $index = $self->{index};
    my $query = $self->{query};
    my %opts  = %{ $self->{opts} };
    $opts{size} ||= 100;
    $opts{skip} = 0;
    while (1) {
        my $hits = $index->search($query, %opts);
        $opts{skip} += $hits->each($sub);
        last if $opts{skip} == $hits->total_hits;
    }
    $opts{skip};
}

1;
