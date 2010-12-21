package Catmandu::Index::Simple;
# ABSTRACT: An embedded Catmandu::Index backed by KinoSearch
# VERSION
use Moose;
use KinoSearch::Plan::Schema;
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::Index::Indexer;
use KinoSearch::Search::IndexSearcher;

with 'Catmandu::Index';

has path => (is => 'ro', isa => 'Str', required => 1);

has _analyzer => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_analyzer',
);

has _ft_field_type => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_ft_field_type',
);

has _schema => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_schema',
);

has _indexer => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_indexer',
    predicate => '_has_indexer',
    clearer => '_clear_indexer',
);

has _searcher => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_searcher',
    clearer => '_clear_searcher',
);

sub _build_analyzer {
    KinoSearch::Analysis::PolyAnalyzer->new(language => 'en');
}

sub _build_ft_field_type {
    my $self = shift;
    KinoSearch::Plan::FullTextType->new(analyzer => $self->_analyzer);
}

sub _build_schema {
    my $self = shift;
    my $schema = KinoSearch::Plan::Schema->new;
    $schema->spec_field(name => $self->id_field, type => KinoSearch::Plan::StringType->new);
    $schema;
}

sub _build_indexer {
    my $self = shift;
    KinoSearch::Index::Indexer->new(
        schema => $self->_schema,
        index  => $self->path,
        create => 1,
    );
}

sub _build_searcher {
    my $self = shift;
    KinoSearch::Search::IndexSearcher->new(index => $self->path);
}

sub save {
    my ($self, $obj) = @_;
    my $type   = $self->_ft_field_type;
    my $schema = $self->_schema;
    for my $name (keys %$obj) {
        $schema->spec_field(name => $name, type => $type) if $name ne $self->id_field;
    }
    $self->_indexer->add_doc($obj);
    $obj;
}

sub search {
    my ($self, $query, %opts) = @_;

    $self->commit;

    if (ref $query eq 'HASH') {
        $query = KinoSearch::Search::ANDQuery->new(
            children => [ map {
                KinoSearch::Search::TermQuery->new(field => $_, term => $query->{$_});
            } keys %$query ],
        );
    }

    my $hits = $self->_searcher->hits(
        query => $query,
        num_wanted => $opts{limit} || 50,
        offset => $opts{start} || 0,
    );

    my $id_field = $self->id_field;
    my $objs = [];
    if (my $store = $opts{reify}) {
        while (my $hit = $hits->next) {
            push @$objs, $store->load_strict($hit->{$id_field});
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
    my ($self, $obj) = @_;
    my $id_field = $self->id_field;
    my $id = ref $obj eq 'HASH' ? $obj->{$id_field} :
                                  $obj;
    $id or confess "Missing $id_field";
    $self->_indexer->delete_by_term(field => $id_field, term => $id);
}

sub commit {
    my ($self) = @_;
    if ($self->_has_indexer) {
        $self->_indexer->commit;
        $self->_indexer->optimize;
        $self->_clear_indexer;
        $self->_clear_searcher;
    }
    1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

__END__

=head1 NAME

Catmandu::Index::Simple - an implementation of L<Catmandu::Index> backed by L<KinoSearch>.

=head1 SYNOPSIS

    use Catmandu::Index::Simple

    my $index = Catmandu::Index::Simple->new(path => '/tmp/index');

=head1 DESCRIPTION

See L<Catmandu::Index>.

=head1 METHODS

See L<Catmandu::Index> for the base methods.

Extra methods for this class:

=head2 Class->new(%args)

Takes the following arguments:

path: The path to the L<KinoSearch> index files (required).

=head2 $c->path

Returns the path to the L<KinoSearch> index files as a string.

=head1 SEE ALSO

L<Catmandu::Index>, the Index role.

L<KinoSearch>, the underlying search engine.

