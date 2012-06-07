package CQL::ElasticSearch;

use Catmandu::Sane;
use Catmandu::Util qw(require_package trim);
use CQL::Parser;
use Moo;

has mapping => (is => 'ro');

my $any_field = qr'^(srw|cql)\.(serverChoice|anywhere)$'i;
my $match_all = qr'^(srw|cql)\.allRecords$'i;
my $distance_modifier = qr'\s*\/\s*distance\s*<\s*(\d+)'i;

my $parser;

sub parse {
    my ($self, $query) = @_;
    $parser ||= CQL::Parser->new;
    my $node;
    eval {
        $node = $parser->parse($query);
    } or do {
        my $e = $@;
        die "cql error: $e";
    };
    $self->visit($node);
}

sub visit {
    my ($self, $node) = @_;

    if ($node->isa('CQL::TermNode')) {
        my $term = $node->getTerm;

        if ($term =~ $match_all) {
            return { match_all => {} };
        }

        my $qualifier = $node->getQualifier;
        my $relation  = $node->getRelation;
        my @modifiers = $relation->getModifiers;
        my $base      = lc $relation->getBase;

        if ($base eq 'scr') {
            if ($self->mapping and my $rel = $self->mapping->{default_relation}) {
                $base = $rel;
            } else {
                $base = '=';
            }
        }

        if ($qualifier =~ $any_field) {
            if ($self->mapping and my $idx = $self->mapping->{default_index}) {
                $qualifier = $idx;
            } else {
                $qualifier = '_all';
            }
        }

        my $nested;

        if ($self->mapping and my $indexes = $self->mapping->{indexes}) {
            $qualifier = lc $qualifier;
            $qualifier =~ s/(?<=[^_])_(?=[^_])//g if $self->mapping->{strip_separating_underscores};
            my $mapping = $indexes->{$qualifier} or confess "cql error: unknown index $qualifier";
            $mapping->{op}{$base} or confess "cql error: relation $base not allowed";
            my $op = $mapping->{op}{$base};
            if (ref $op && $op->{field}) {
                $qualifier = $op->{field};
            } elsif ($mapping->{field}) {
                $qualifier = $mapping->{field};
            }

            my $filters;
            if (ref $op && $op->{filter}) {
                $filters = $op->{filter};
            } elsif ($mapping->{filter}) {
                $filters = $mapping->{filter};
            }
            if ($filters) {
                for my $filter (@$filters) {
                    given ($filter) {
                        when ('lowercase') { $term = lc $term }
                    }
                }
            }
            if (ref $op && $op->{cb}) {
                my ($pkg, $sub) = @{$op->{cb}};
                $term = require_package($pkg)->$sub($term);
            } elsif ($mapping->{cb}) {
                my ($pkg, $sub) = @{$mapping->{cb}};
                $term = require_package($pkg)->$sub($term);
            }

            $nested = $mapping->{nested};
        }

        my $query = _term_node($base, $qualifier, $term, @modifiers);

        if ($nested) {
            if ($nested->{query}) {
                $query = { bool => { must => [
                    $nested->{query},
                    $query,
                ] } };
            }
            $query = { nested => {
                path  => $nested->{path},
                query => $query,
            } };
        }

        return $query;
    }

    if ($node->isa('CQL::ProxNode')) { # TODO mapping
        my $slop = 0;
        my $qualifier = $node->left->getQualifier;
        my $term = join ' ', $node->left->getTerm, $node->right->getTerm;
        if (my ($n) = $node->op =~ $distance_modifier) {
            $slop = $n - 1 if $n > 1;
        }
        if ($qualifier =~ $any_field) {
            $qualifier = '_all';
        }

        return { text_phrase => { $qualifier => { query => $term, slop => $slop } } };
    }

    if ($node->isa('CQL::BooleanNode')) {
        my $op = lc $node->op;
        my $bool;
        if ($op eq 'and') {
            return { bool => { must => [
                $self->visit($node->left),
                $self->visit($node->right)
            ] } };
        }

        if ($op eq 'or') {
            return { bool => { should => [
                $self->visit($node->left),
                $self->visit($node->right)
            ] } };
        }

        { bool => { must => [
            $self->visit($node->left),
            { bool => { must_not => [
                $self->visit($node->right)
            ] } }
        ] } };
    }
}

sub _term_node {
    my ($base, $qualifier, $term, @modifiers) = @_;
    my $q;
    if ($base eq '=') {
        if (ref $qualifier) {
            return { bool => { should => [ map {
                if ($_ eq '_id') {
                    { ids => { values => [$term] } };
                } else {
                    _text_node($_, $term, @modifiers);
                }
            } @$qualifier ] } };
        } else {
            if ($qualifier eq '_id') {
                return { ids => { values => [$term] } };
            }
            return _text_node($qualifier, $term, @modifiers);
        }
    } elsif ($base eq '<') {
        if (ref $qualifier) {
            return { bool => { should => [ map { { range => { $_ => { lt => $term } } } } @$qualifier ] } };
        } else {
            return { range => { $qualifier => { lt => $term } } };
        }
    } elsif ($base eq '>') {
        if (ref $qualifier) {
            return { bool => { should => [ map { { range => { $_ => { gt => $term } } } } @$qualifier ] } };
        } else {
            return { range => { $qualifier => { gt => $term } } };
        }
    } elsif ($base eq '<=') {
        if (ref $qualifier) {
            return { bool => { should => [ map { { range => { $_ => { lte => $term } } } } @$qualifier ] } };
        } else {
            return { range => { $qualifier => { lte => $term } } };
        }
    } elsif ($base eq '>=') {
        if (ref $qualifier) {
            return { bool => { should => [ map { { range => { $_ => { gte => $term } } } } @$qualifier ] } };
        } else {
            return { range => { $qualifier => { gte => $term } } };
        }
    } elsif ($base eq '<>') {
        if (ref $qualifier) {
            return { bool => { must_not => [ map {
                if ($_ eq '_id') {
                    { ids => { values => [$term] } };
                } else {
                    { text_phrase => { $_ => { query => $term } } };
                }
            } @$qualifier ] } };
        } else {
            if ($qualifier eq '_id') {
                return { bool => { must_not => [ { ids => { values => [$term] } } ] } };
            }
            return { bool => { must_not => [ { text_phrase => { $qualifier => { query => $term } } } ] } };
        }
    } elsif ($base eq 'exact') {
        if (ref $qualifier) {
            return { bool => { should => [ map {
                if ($_ eq '_id') {
                    { ids => { values => [$term] } };
                } else {
                    { text_phrase => { $_ => { query => $term } } };
                }
            } @$qualifier ] } };
        } else {
            if ($qualifier eq '_id') {
                return { ids => { values => [$term] } };
            }
            return { text_phrase => { $qualifier => { query => $term } } };
        }
    } elsif ($base eq 'any') {
        $term = [split /\s+/, trim($term)];
        if (ref $qualifier) {
            return { bool => { should => [ map {
                $q = $_;
                map { _text_node($q, $_) } @$term;
            } @$qualifier ] } };
        } else {
            return { bool => { should => [map { _text_node($qualifier, $_) } @$term] } };
        }
    } elsif ($base eq 'all') {
        $term = [split /\s+/, trim($term)];
        if (ref $qualifier) {
            return { bool => { should => [ map {
                $q = $_;
                { bool => { must => [map { _text_node($q, $_) } @$term] } };
            } @$qualifier ] } };
        } else {
            return { bool => { must => [map { _text_node($qualifier, $_) } @$term] } };
        }
    } elsif ($base eq 'within') {
        my @range = split /\s+/, $term;
        if (@range == 1) {
            if (ref $qualifier) {
                return { bool => { should => [ map { { text => { $_ => { query => $term } } } } @$qualifier ] } };
            } else {
                return { text => { $qualifier => { query => $term } } };
            }
        }
        if (ref $qualifier) {
            return { bool => { should => [ map { { range => { $_ => { lte => $range[0], gte => $range[1] } } } } @$qualifier ] } };
        } else {
            return { range => { $qualifier => { lte => $range[0], gte => $range[1] } } };
        }
    }

    if (ref $qualifier) {
        return { bool => { should => [ map {
            _text_node($_, $term, @modifiers);
        } @$qualifier ] } };
    } else {
        return _text_node($qualifier, $term, @modifiers);
    }
}

sub _text_node {
    my ($qualifier, $term, @modifiers) = @_;
    if ($term =~ /[^\\][\*\?]/) { # TODO only works for single terms, mapping
        return { wildcard => { $qualifier => { value => $term } } };
    }
    for my $m (@modifiers) {
        if ($m->[1] eq 'fuzzy') { # TODO only works for single terms, mapping fuzzy_factor
            return { fuzzy => { $qualifier => { value => $term, max_expansions => 10, min_similarity => 0.75 } } };
        }
    }
    if ($term =~ /\s/) {
        return { text_phrase => { $qualifier => { query => $term } } };
    }
    { text => { $qualifier => { query => $term } } };
}

1;

=head1 NAME

CQL::ElasticSearch - Converts a CQL query string to a ElasticSearch query hashref

=head1 SYNOPSIS

    $es_query_hashref = CQL::ElasticSearch->parse($cql_query_string);

=head1 DESCRIPTION

This package currently parses most of CQL 1.1:

    and
    or
    not
    prox
    prox/distance<$n
    srw.allRecords
    srw.serverChoice
    srw.anywhere
    cql.allRecords
    cql.serverChoice
    cql.anywhere
    =
    scr
    =/fuzzy
    scr/fuzzy
    <
    >
    <=
    >=
    <>
    exact
    all
    any
    within

=head1 METHODS

=head2 parse

Parses the given CQL query string with L<CQL::Parser> and converts it to a ElasticSearch query hashref.

=head2 visit

Converts the given L<CQL::Node> to a ElasticSearch query hashref.

=head1 TODO

support cql 1.2, more modifiers (esp. all of masked), sortBy, encloses

=head1 SEE ALSO

L<CQL::Parser>.

=cut

