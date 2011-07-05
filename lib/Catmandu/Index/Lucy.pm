package Catmandu::Index::Lucy;
use Catmandu::Sane;
use Catmandu::Util qw(quack assert_id);
use Lucy::Plan::Schema;
use Lucy::Plan::FullTextType;
use Lucy::Analysis::PolyAnalyzer;
use Lucy::Index::Indexer;
use Lucy::Search::IndexSearcher;
use Catmandu::Object
    path => 'r',
    _analyzer      => { default => '_build_analyzer' },
    _ft_field_type => { default => '_build_ft_field_type' },
    _schema        => { default => '_build_schema' },
    _indexer       => { default => '_build_indexer' },
    _searcher      => { default => '_build_searcher' };

sub _build_analyzer {
    Lucy::Analysis::PolyAnalyzer->new(language => 'en');
}

sub _build_ft_field_type {
    my $self = $_[0];
    Lucy::Plan::FullTextType->new(analyzer => $self->_analyzer);
}

sub _build_schema {
    my $self = $_[0];
    my $schema = Lucy::Plan::Schema->new;
    $schema->spec_field(name => '_id', type => Lucy::Plan::StringType->new);
    $schema;
}

sub _build_indexer {
    my $self = $_[0];
    Lucy::Index::Indexer->new(schema => $self->_schema, index => $self->path, create => 1);
}

sub _build_searcher {
    my $self = $_[0];
    Lucy::Search::IndexSearcher->new(index => $self->path);
}

sub _add {
    my ($self, $obj) = @_;
    assert_id($obj);
    my $type   = $self->_ft_field_type;
    my $schema = $self->_schema;
    for my $name (keys %$obj) {
        $schema->spec_field(name => $name, type => $type) if $name ne '_id';
    }
    $self->_indexer->add_doc($obj);
    $obj;
}

sub add {
    my ($self, $obj) = @_;
    if (quack $obj, 'each') {
        $obj->each(sub { $self->_add($_[0]) });
    } else {
        $self->_add($obj);
    }
}

sub search {
    my ($self, $query, %opts) = @_;

    if (ref $query eq 'HASH') {
        $query = Lucy::Search::ANDQuery->new(
            children => [ map {
                Lucy::Search::TermQuery->new(field => $_, term => $query->{$_});
            } keys %$query ],
        );
    }

    my $hits = $self->_searcher->hits(
        query => $query,
        num_wanted => $opts{size} || 50,
        offset => $opts{skip} || 0,
    );

    my $objs = [];

    if (my $store = $opts{reify}) {
        while (my $hit = $hits->next) {
            push @$objs, $store->get($hit->{_id});
        }
    } else {
        while (my $hit = $hits->next) {
            push @$objs, $hit->get_fields;
        }
    }

     return $objs,
            $hits->total_hits;
}

sub delete {
    my ($self, $id) = @_;
    $self->_indexer->delete_by_term(field => '_id', term => assert_id($id));
}

sub delete_where {
    my ($self, $query) = @_;

    if (! ref $query) {
        $query = Lucy::Search::QueryParser->new(schema => $self->_schema)->parse($query);
    } elsif (ref $query eq 'HASH') {
        my $terms = [ map {
            Lucy::Search::TermQuery->new(field => $_, term => $query->{$_});
        } keys %$query ];
        $query = Lucy::Search::ANDQuery->new(children => $terms);
    }

    $self->_indexer->delete_by_query($query);
}

sub delete_all {
    my ($self) = @_;
    $self->delete_where(Lucy::Search::MatchAllQuery->new);
}

sub commit { # TODO optimize
    my ($self) = @_;

    if ($self->{_indexer}) {
        $self->{_indexer}->commit;
        delete $self->{_indexer};
        delete $self->{_searcher};
    }
}

1;
