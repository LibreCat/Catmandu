package CQL::Solr; #TODO see CQL::ElasticSearch
use strict;
use warnings;
use CQL::Parser;

my $any_field = qr/^(srw|cql)\.(serverChoice|anywhere)$/i;
my $match_all = qr/^(srw|cql)\.allRecords$/i;
my $distance_modifier = qr/\s*\/\s*distance\s*<\s*(\d+)/i;
my $reserved = qr/[\+\-\&\|\!\(\)\{\}\[\]\^\"\~\*\?\:\\]/;

my $parser;

sub parse {
    my ($self, $query) = @_;
    $parser ||= CQL::Parser->new;
    $self->visit($parser->parse($query));
}

sub _escape_term {
    my $term = $_[0];
    $term =~ s/($reserved)/\\$1/g;
    $term;
}

sub visit {
    my ($self, $node) = @_;

    if ($node->isa('CQL::TermNode')) {
        my $qualifier = $node->getQualifier;

        if ($qualifier =~ $match_all) {
            return "*:*";
        }

        my $relation  = $node->getRelation;
        my $term      = _escape_term($node->getTerm);
        my @modifiers = $relation->getModifiers;
        my $base      = lc $relation->getBase;

        if ($qualifier =~ $any_field) {
            $qualifier = "";
        } else {
            $qualifier = "$qualifier:";
        }

        if ($base eq '=' or $base eq 'scr') {
            for my $m (@modifiers) {
                if ($m->[1] eq 'fuzzy') {
                    return "$qualifier$term~";
                }
            }
            return $qualifier.$term;
        } elsif ($base eq '<') {
            return $qualifier."{* TO $term}";
        } elsif ($base eq '>') {
            return $qualifier."{$term TO *}";
        } elsif ($base eq '<=') {
            return $qualifier."[* TO $term]";
        } elsif ($base eq '>=') {
            return $qualifier."[$term TO *]";
        } elsif ($base eq '<>') {
            return "-$qualifier$term";
        } elsif ($base eq 'exact') {
            return $qualifier.$term;
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
            return $qualifier.$term;
        }
    }

    if ($node->isa('CQL::ProxNode')) {
        my $distance = 1;
        my $qualifier = $node->left->getQualifier;
        my $term = _escape_term(join(' ', $node->left->getTerm, $node->right->getTerm));

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
