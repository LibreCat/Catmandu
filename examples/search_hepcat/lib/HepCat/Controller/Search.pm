package Hepcat::Controller::Search;
use Dancer ':syntax';

our $VERSION = '0.1';

use HepCat::Model::Search;
use POSIX qw(ceil floor);

any ['get', 'post'] => '/search' => sub {
    my $q     = params->{q};
    my $start = params->{start} || 0;
    my $num   = params->{num} || 10;

    my ($results, $hits, $error) =
      HepCat::Model::Search->search($q, start => $start, limit => $num);

    my $more = ($start + $num < $hits) ? $start + $num : -1;
    my $prev = ($start - $num >= 0)    ? $start - $num : -1;
    my $end  = ($start + $num < $hits) ? $start + $num : $hits;

    my ($spage, $curr, $epage) = _paginate($start, $num, $hits);

    session q => $q;

    template 'index',
      { q       => $q,
        error   => $error,
        hits    => $hits,
        results => $results,
        more    => $more,
        prev    => $prev,
        start   => $start + 1,
        finish  => $end,
        num     => $num,
        spage   => $spage,
        curr    => $curr,
        epage   => $epage,
      };
};

get '/view/:id' => sub {
    my $id = params->{id};
    my $obj = HepCat::Model::Catmandu->store->load($id);
    template 'view', { id => $id, res => $obj, q => session->{q} };
};

sub _paginate {
    my ($start, $num, $hits) = @_;

    my $curr = floor($start / $num);
    my $last = ceil($hits / $num);

    my $spage = $curr - 10 > 0     ? $curr - 10 : 1;
    my $epage = $curr + 10 < $last ? $curr + 10 : $last;

    return ($spage, $curr, $epage);
}

1;

