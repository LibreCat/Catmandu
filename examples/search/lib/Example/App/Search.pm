package Example::App::Search;
use Catmandu::Sane;
use Dancer qw(:syntax);
use Dancer::Plugin::Catmandu;

get '/opensearch.xml' => sub {
    content_type 'application/xml';
    template 'opensearch.xml', {}, {layout => 0};
};

get '/' => sub {
    if (my $qs   = params->{qs}) {
        my $limit = params->{limit} || 15;
        my $start = params->{start} || 0;
        $limit = 1000 if $limit > 1000;
        $start = 0    if $start < 0;

        my $res = get_index->search($qs, limit => $limit, start => $start);

        return template 'hits', {
            qs => $qs,
            start => $start,
            limit => $limit,
            total => $res->total,
            hits => $res->hits,
        };
    }
    template 'index';
};

1;
