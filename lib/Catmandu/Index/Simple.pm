package Catmandu::Index::Simple;

use Moose;
use KinoSearch::Plan::Schema;
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::Index::Indexer;
use KinoSearch::Search::IndexSearcher;

with 'Catmandu::Index';

has fields => (is => 'ro', isa => 'ArrayRef', required => 1);
has path => (is => 'ro', isa => 'Str', required => 1);

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

sub _build_schema {
    my $self = shift;

    my $schema = KinoSearch::Plan::Schema->new;
    my $analyzer = KinoSearch::Analysis::PolyAnalyzer->new(language => 'en');
    my $ft_type = KinoSearch::Plan::FullTextType->new(analyzer => $analyzer);

    foreach my $name (@{$self->fields}) {
        $schema->spec_field(name => $name, type => $ft_type);
    }

    $schema->spec_field(name => '_id',
                        type => KinoSearch::Plan::StringType->new);

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
    $self->_indexer->add_doc($obj);
    $obj;
}

sub find {
    my ($self, $query, %opts) = @_;

    $self->commit;

    my $hits = $self->_searcher->hits(
        query => $query,
        num_wanted => $opts{want} || 50,
        offset => $opts{skip} || 0,
    );

    my $objs = [];
    if (my $store = $opts{reify}) {
        while (my $hit = $hits->next) {
            push @$objs, $store->load_strict($hit->{_id});
        }
    } else {
        while (my $hit = $hits->next) {
            push @$objs, $hit;
        }
    }
    return $objs,
           $hits->total_hits;
}

sub delete {
    my ($self, $obj) = @_;
    my $id = ref $obj eq 'HASH' ? $obj->{_id} :
                                  $obj;
    $id or confess "Missing _id";
    $self->_indexer->delete_by_term(field => '_id', term => $id);
}

sub commit {
    my ($self) = @_;
    if ($self->_has_indexer) {
        $self->_indexer->commit;
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

