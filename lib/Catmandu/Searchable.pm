package Catmandu::Searchable;

use Catmandu::Sane;
use Moo::Role;

requires 'translate_sru_sortkeys';
requires 'translate_cql_query';
requires 'search';
requires 'searcher';
requires 'delete_by_query';

has maximum_limit => (is => 'ro', builder => '_build_maximum_limit');
has default_limit => (is => 'ro', builder => '_build_default_limit');

sub _build_maximum_limit { 1000 }
sub _build_default_limit { 10 }

sub normalize_query { $_[1] }

my $AROUND_SEARCH = sub {
    my ($orig, $self, %args) = @_;
    $args{limit} //= $self->default_limit;
    $args{start} //= 0;
    if ($args{limit} > $self->maximum_limit) {
        $args{limit} = $self->maximum_limit;
    }
    if ($args{start} < 0) {
        $args{start} = 0;
    }
    $args{start}+=0;
    $args{limit}+=0;
    if (my $sru_sortkeys = delete $args{sru_sortkeys}) {
        $args{sort} = $self->translate_sru_sortkeys($sru_sortkeys);
    }
    if (my $cql_query = delete $args{cql_query}) {
        $args{query} = $self->translate_cql_query($cql_query);
    }
    $args{query} = $self->normalize_query($args{query});
    $orig->($self, %args);
};

around search   => $AROUND_SEARCH;
around searcher => $AROUND_SEARCH;

around delete_by_query => sub {
    my ($orig, $self, %args) = @_;
    if (my $cql = delete $args{cql_query}) {
        $args{query} = $self->translate_cql_query($cql);
    }
    $args{query} = $self->normalize_query($args{query});
    $orig->($self, %args);
    return;
};

1;
