package CQL::ElasticSearch; # TODO support cql 1.2, more modifiers, sortBy, encloses
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
            for my $m (@modifiers) {
                if ($m->[1] eq 'fuzzy') {
                    $term = { query => $term, fuzziness => 0.5 };
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
            return { bool => { must_not => [ { text => { $qualifier => $term } } ] } };
        } elsif ($base eq 'exact') {
            return { text => { $qualifier => $term } };
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
            return { text => { $qualifier => $term } };
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
