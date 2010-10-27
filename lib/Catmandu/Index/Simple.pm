package Catmandu::Index::Simple;

use Any::Moose;
use KinoSearch::InvIndexer;
use KinoSearch::Index::Term;
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::Searcher;

with 'Catmandu::Index';

has path => (is => 'ro', isa => 'Str', required => 1);

has _analyzer => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_analyzer',
);

has _indexer => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_indexer',
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

sub _build_indexer {
    my $indexer = KinoSearch::InvIndexer->new(
        invindex => $_[0]->path,
        analyzer => $_[0]->_analyzer,
        create   => 1,
    );
    $indexer->spec_field(name => '_id', analyzed => 0, vectorized => 0);
    $indexer;
}

sub _build_searcher {
    KinoSearch::Searcher->new(
        invindex => $_[0]->path,
        analyzer => $_[0]->_analyzer,
    );
}

sub save {
    my ($self, $obj) = @_;
    my $doc = $self->_indexer->new_doc;
    while (my ($key, $val) = each %$obj) {
        $doc->set_value($key => $val);
    }
    $self->_indexer->add_doc($doc);
    $obj;
}

sub find {
    my ($self, $query, %opts) = @_;
    my $hits = $self->_searcher->search(query => $query);
    my $objs = [];
    $hits->seek($opts{skip} || 0, $opts{limit} || 50);
    while (my $obj = $hits->fetch_hit_hashref) {
        push @$objs, $obj;
    }
    return $objs,
           $hits->total_hits;
}

sub delete {
    my ($self, $obj) = @_;
    my $id = ref $obj eq 'HASH' ? $obj->{_id} :
                                  $obj;
    $id or confess "Missing _id";
    my $term = KinoSearch::Index::Term->new('_id', $id);
    $self->_indexer->delete_docs_by_term($term);
}

sub done {
    my ($self) = @_;
    $self->_indexer->finish(optimize => 1);
    $self->_clear_searcher;
    $self->_clear_indexer;
    1;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
__PACKAGE__;

