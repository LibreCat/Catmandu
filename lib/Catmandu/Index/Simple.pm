package Catmandu::Index::Simple;

use Any::Moose;
use KinoSearch::InvIndexer;
use KinoSearch::Index::Term;
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::Searcher;

with 'Catmandu::Index';

has fields => (is => 'ro', isa => 'HashRef', required => 1);
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

sub BUILD {
    my $self = shift;
    my $id_field = $self->fields->{_id} ||= {};
    $id_field->{vectorized} = 0;
    $id_field->{analyzed}   = 0;
}

sub _build_analyzer {
    KinoSearch::Analysis::PolyAnalyzer->new(language => 'en');
}

sub _build_indexer {
    my $self = shift;
    my $indexer = KinoSearch::InvIndexer->new(
        invindex => $self->path,
        analyzer => $self->_analyzer,
        create   => 1,
    );
    while (my ($name, $spec) = each %{$self->fields}) {
        $indexer->spec_field(%$spec, name => $name);
    }
    $indexer;
}

sub _build_searcher {
    my $self = shift;
    KinoSearch::Searcher->new(
        invindex => $self->path,
        analyzer => $self->_analyzer,
    );
}

sub save {
    my ($self, $obj) = @_;
    my $doc = $self->_indexer->new_doc;
    while (my ($field, $value) = each %$obj) {
        $self->fields->{$field} or return;
        $doc->set_value($field => $value);
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

