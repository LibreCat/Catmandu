package CQL::ElasticSearch;
use strict;
use warnings;
use CQL::Parser;

my $any_field = qr/^(srw|cql)\.(serverChoice|anywhere)$/i;
my $match_all = qr/^(srw|cql)\.allRecords$/i;
my $distance_modifier = qr/\s*\/\s*distance\s*<\s*(\d+)/i;

my $parser;

sub parse {
    my ($self, $query) = @_;
    $parser ||= CQL::Parser->new;
    $self->visit($parser->parse($query));
}

sub visit {
    my ($self, $node) = @_;

    if ($node->isa('CQL::TermNode')) {
        my $qualifier = $node->getQualifier;

        if ($qualifier =~ $match_all) {
            return { '-all' => 1 };
        }

        my $relation  = $node->getRelation;
        my $term      = $node->getTerm;
        my @modifiers = $relation->getModifiers;
        my $base      = lc $relation->getBase;

        if ($qualifier =~ $any_field) {
            $qualifier = '_all';
        }

        if ($base eq '=' or $base eq 'scr') {
            $term = { query => $term, operator => 'AND' };
            for my $m (@modifiers) {
                if ($m->[1] eq 'fuzzy') {
                    $term->{fuzziness} = 0.5;
                    last;
                }
            }
            return { text => { $qualifier => $term } };
        } elsif ($base eq '<') {
            return { range => { $qualifier => { lt => $term } } };
        } elsif ($base eq '>') {
            return { range => { $qualifier => { gt => $term } } };
        } elsif ($base eq '<=') {
            return { range => { $qualifier => { lte => $term } } };
        } elsif ($base eq '>=') {
            return { range => { $qualifier => { gte => $term } } };
        } elsif ($base eq '<>') {
            return { bool => { must_not => [ { text => { $qualifier => { query => $term, operator => 'AND' } } } ] } };
        } elsif ($base eq 'exact') {
            return { text => { $qualifier => { query => $term, operator => 'AND' } } };
        } elsif ($base eq 'all') {
            my @terms = split /\s+/, $term;
            return { bool => { must => [ map { { text => { $qualifier => $_ } } } @terms ] } };
        } elsif ($base eq 'any') {
            my @terms = split /\s+/, $term;
            return { bool => { should => [ map { { text => { $qualifier => $_ } } } @terms ] } };
        } elsif ($base eq 'within') {
            my @range = split /\s+/, $term;
            if (@range == 1) {
                return { text => { $qualifier => $term } };
            } else {
                return { range => { $qualifier => { lte => $range[0], gte => $range[1] } } };
            }
        } else {
            return { text => { $qualifier => { query => $term, operator => 'AND' } } };
        }
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

support cql 1.2, more modifiers, sortBy, encloses

=head1 SEE ALSO

L<CQL::Parser>.

=cut

