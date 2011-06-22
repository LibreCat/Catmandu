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
        my $size = params->{size} || 15;
        my $skip = params->{skip} || 0;
        $size = 1000 if $size > 1000;
        $skip = 0    if $skip < 0;

        my ($hits, $total_hits) = get_index->search($qs, size => $size, skip => $skip);

        return template 'hits', {
            qs => $qs,
            skip => $skip,
            size => $size,
            total_hits => $total_hits,
            hits => $hits,
        };
    }
    template 'index';
};

1;
