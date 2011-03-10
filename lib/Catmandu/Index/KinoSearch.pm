package Catmandu::Index::KinoSearch;
use KinoSearch::Plan::Schema;
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::Index::Indexer;
use KinoSearch::Search::IndexSearcher;
use Catmandu::Class qw(path);
use parent qw(
    Catmandu::Modifiable
    Catmandu::Pluggable
);

sub plugin_namespace { 'Catmandu::Index::Plugin' }

sub build {
    my ($self, $args) = @_;
    $self->{path} = $args->{path} || confess("Attribute path is required");
}

sub analyzer {
    my $self = $_[0];
    $self->{analyzer} ||= KinoSearch::Analysis::PolyAnalyzer->new(language => 'en');
}

sub ft_field_type {
    my $self = $_[0];
    $self->{ft_field_type} ||= KinoSearch::Plan::FullTextType->new(analyzer => $self->analyzer);
}

sub schema {
    my $self = $_[0];
    $self->{schema} ||= do {
        my $schema = KinoSearch::Plan::Schema->new;
        $schema->spec_field(name => '_id', type => KinoSearch::Plan::StringType->new);
        $schema;
    };
}

sub indexer {
    my $self = $_[0];
    $self->{indexer} ||= KinoSearch::Index::Indexer->new(
        schema => $self->schema,
        index  => $self->path,
        create => 1,
    );
}

sub searcher {
    my $self = $_[0];
    $self->{searcher} ||= KinoSearch::Search::IndexSearcher->new(index => $self->path);
}

sub save {
    my ($self, $obj) = @_;
    $obj->{_id} or confess "_id missing";
    my $type   = $self->ft_field_type;
    my $schema = $self->schema;
    for my $name (keys %$obj) {
        $schema->spec_field(name => $name, type => $type) if $name ne '_id';
    }
    $self->indexer->add_doc($obj);
    $obj;
}

sub search {
    my ($self, $query, %opts) = @_;

    $self->commit;

    if (ref $query) {
        $query = KinoSearch::Search::ANDQuery->new(
            children => [ map {
                KinoSearch::Search::TermQuery->new(field => $_, term => $query->{$_});
            } keys %$query ],
        );
    }

    my $hits = $self->searcher->hits(
        query => $query,
        num_wanted => $opts{limit} || 50,
        offset => $opts{start} || 0,
    );

    my $objs = [];
    if (my $store = $opts{reify}) {
        while (my $hit = $hits->next) {
            push @$objs, $store->load($hit->{_id}) || confess("Not found");
        }
    } else {
        while (my $hit = $hits->next) {
            push @$objs, $hit->get_fields;
        }
    }

    ($objs, $hits->total_hits);
}

sub delete {
    my ($self, $id) = @_;
    $id = $id->{_id} if ref $id eq 'HASH';
    $id or confess "_id missing";
    $self->indexer->delete_by_term(field => '_id', term => $id);
}

sub delete_by_query {
    my ($self, $query) = @_;
    if (ref $query) {
        $query = KinoSearch::Search::ANDQuery->new(
            children => [ map {
                KinoSearch::Search::TermQuery->new(field => $_, term => $query->{$_});
            } keys %$query ],
        );
    } else {
        $query = KinoSearch::Search::QueryParser->new(schema => $self->schema)->parse($query);
    }
    $self->indexer->delete_by_query($query);
}

sub commit {
    my ($self) = @_;
    if ($self->{indexer}) {
        $self->{indexer}->commit;
        $self->{indexer}->optimize;
        delete $self->{indexer};
        delete $self->{searcher};
    }
    $self;
}

1;
