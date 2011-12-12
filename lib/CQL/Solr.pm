package CQL::Solr; #TODO see CQL::ElasticSearch
use strict;
use warnings;
use CQL::Parser;

my $any_field = qr'^(srw|cql)\.(serverChoice|anywhere)$'i;
my $match_all = qr'^(srw|cql)\.allRecords$'i;
my $distance_modifier = qr'\s*\/\s*distance\s*<\s*(\d+)'i;
my $reserved = qr'[\+\-\&\|\!\(\)\{\}\[\]\^\"\~\*\?\:\\]';

my $parser;

sub parse {
    my ($self, $query) = @_;
    $parser ||= CQL::Parser->new;
    $self->visit($parser->parse($query));
}

sub escape_term {
    my $term = $_[0];
    $term =~ s/($reserved)/\\$1/g;
    $term;
}

sub quote_term {
    my $term = $_[0];
    $term = qq("$term") if $term =~ /\s/;
    $term;
}

sub visit {
    my ($self, $node) = @_;

    if ($node->isa('CQL::TermNode')) {
        my $term = escape_term($node->getTerm);

        if ($term =~ $match_all) {
            return "*:*";
        }

        my $qualifier = $node->getQualifier;
        my $relation  = $node->getRelation;
        my @modifiers = $relation->getModifiers;
        my $base      = lc $relation->getBase;

        if ($qualifier =~ $any_field) {
            $qualifier = "";
        } else {
            $qualifier = "$qualifier:";
        }

        if ($base eq '=' or $base eq 'scr') {
            $term = quote_term($term);
            for my $m (@modifiers) {
                if ($m->[1] eq 'fuzzy') {
                    return "$qualifier$term~";
                }
            }
            return $qualifier.$term;
        } elsif ($base eq '<') {
            $term = quote_term($term);
            return $qualifier."{* TO $term}";
        } elsif ($base eq '>') {
            $term = quote_term($term);
            return $qualifier."{$term TO *}";
        } elsif ($base eq '<=') {
            $term = quote_term($term);
            return $qualifier."[* TO $term]";
        } elsif ($base eq '>=') {
            $term = quote_term($term);
            return $qualifier."[$term TO *]";
        } elsif ($base eq '<>') {
            $term = quote_term($term);
            return "-$qualifier$term";
        } elsif ($base eq 'exact') {
            return $qualifier.quote_term($term);
        } elsif ($base eq 'all') {
            my @terms = split /\s+/, $term;
            if (@terms == 1) {
                return $qualifier.$term;
            }
            $term = join ' ', map { "+$_" } @terms;
            if ($qualifier) {
                return "$qualifier($term)";
            }
            return $term;
        } elsif ($base eq 'any') {
            $term = join ' OR ', map { $qualifier.$_ } split /\s+/, $term;
            return "($term)";
        } elsif ($base eq 'within') {
            my @range = split /\s+/, $term;
            if (@range == 1) {
                return $qualifier.$term;
            } else {
                return $qualifier."[$range[0] TO $range[1]]";
            }
        } else {
            return $qualifier.quote_term($term);
        }
    }

    if ($node->isa('CQL::ProxNode')) {
        my $distance = 1;
        my $qualifier = $node->left->getQualifier;
        my $term = escape_term(join(' ', $node->left->getTerm, $node->right->getTerm));

        if (my ($n) = $node->op =~ $distance_modifier) {
            $distance = $n if $n > 1;
        }

        if ($qualifier =~ $any_field) {
            return qq("$term"~$distance);
        } else {
            return qq($qualifier:"$term"~$distance);
        }
    }

    if ($node->isa('CQL::BooleanNode')) {
        my $lft = $node->left;
        my $rgt = $node->right;
        my $lft_q = $self->visit($lft);
        my $rgt_q = $self->visit($rgt);
        $lft_q = "($lft_q)" unless $lft->isa('CQL::TermNode') || $lft->isa('CQL::ProxNode');
        $rgt_q = "($rgt_q)" unless $rgt->isa('CQL::TermNode') || $rgt->isa('CQL::ProxNode');

        return join ' ', $lft_q, uc $node->op, $rgt_q;
    }
}

1;

=head1 NAME

CQL::Solr - Converts a CQL query string to a Solr query string

=head1 SYNOPSIS

    $solr_query_string = CQL::Solr->parse($cql_query_string);

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

Parses the given CQL query string with L<CQL::Parser> and converts it to a Solr query string.

=head2 visit

Converts the given L<CQL::Node> to a Solr query string.

=head1 TODO

support cql 1.2, more modifiers (esp. masked), sortBy, encloses

=head1 SEE ALSO

L<CQL::Parser>.

=cut

