package CQL::ElasticSearch;
use strict;
use warnings;
use CQL::Parser;

my $any_field = qr'^(srw|cql)\.(serverChoice|anywhere)$'i;
my $match_all = qr'^(srw|cql)\.allRecords$'i;
my $distance_modifier = qr'\s*\/\s*distance\s*<\s*(\d+)'i;

my $parser;

sub parse {
    my ($self, $query) = @_;
    $parser ||= CQL::Parser->new;
    $self->visit($parser->parse($query));
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

        if ($qualifier =~ $any_field) {
            $qualifier = '_all';
        }

        if ($base eq '=' || $base eq 'scr') {
            return _text_node($qualifier, $term, @modifiers);
        } elsif ($base eq '<') {
            return { range => { $qualifier => { lt => $term } } };
        } elsif ($base eq '>') {
            return { range => { $qualifier => { gt => $term } } };
        } elsif ($base eq '<=') {
            return { range => { $qualifier => { lte => $term } } };
        } elsif ($base eq '>=') {
            return { range => { $qualifier => { gte => $term } } };
        } elsif ($base eq '<>') {
            return { bool => { must_not => [ _text_node($qualifier, $_, @modifiers) ] } };
        } elsif ($base eq 'exact') {
            return { text_phrase => { $qualifier => { query => $term } } };
        } elsif ($base eq 'any') {
            my @terms = split /\s+/, $term;
            return { bool => { should => [ map { _text_node($qualifier, $_, @modifiers) } @terms ] } };
        } elsif ($base eq 'all') {
            my @terms = split /\s+/, $term;
            return { bool => { must => [ map { _text_node($qualifier, $_, @modifiers) } @terms ] } };
        } elsif ($base eq 'within') {
            my @range = split /\s+/, $term;
            if (@range == 1) {
                return { text => { $qualifier => $term } };
            }
            return { range => { $qualifier => { lte => $range[0], gte => $range[1] } } };
        }
        return _text_node($qualifier, $term, @modifiers);
    }

    if ($node->isa('CQL::ProxNode')) {
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
        if ($op eq 'and') { $bool = 'must' }
        elsif ($op eq 'or') { $bool = 'should' }
        else { $bool = 'must_not' }

        return { bool => { $bool => [
            $self->visit($node->left),
            $self->visit($node->right)
        ] } };
    }
}

sub _text_node {
    my ($qualifier, $term, @modifiers) = @_;
    if ($term =~ /^\^./) {
        return { text_phrase_prefix => { $qualifier => { query => substr($term, 1), max_expansions => 10 } } };
    } elsif ($term =~ /[^\\][*?]/) {
        return { wildcard => { $qualifier => $term } };
    }
    for my $m (@modifiers) {
        if ($m->[1] eq 'fuzzy') {
            return { text_phrase => { $qualifier => { query => $term, fuzziness => 0.5 } } };
        }
    }
    { text_phrase => { $qualifier => { query => $term } } };
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

