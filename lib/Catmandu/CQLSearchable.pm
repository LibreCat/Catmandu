package Catmandu::CQLSearchable;

use Catmandu::Sane;

our $VERSION = '1.0306';

use Moo::Role;
use namespace::clean;

with 'Catmandu::Searchable';

requires 'translate_sru_sortkeys';
requires 'translate_cql_query';

my $AROUND_SEARCH = sub {
    my ($orig, $self, %args) = @_;

    if (my $sru_sortkeys = delete $args{sru_sortkeys}) {
        $args{sort} = $self->translate_sru_sortkeys($sru_sortkeys);
    }
    if (my $cql_query = delete $args{cql_query}) {
        $args{query} = $self->translate_cql_query($cql_query);
    }

    $orig->($self, %args);
};

around search   => $AROUND_SEARCH;
around searcher => $AROUND_SEARCH;

around delete_by_query => sub {
    my ($orig, $self, %args) = @_;

    if (my $cql = delete $args{cql_query}) {
        $args{query} = $self->translate_cql_query($cql);
    }

    $orig->($self, %args);
    return;
};

1;

__END__

=pod

=head1 NAME

Catmandu::CQLSearchable - Optional role for CQL searchable stores

=head1 SEE ALSO

L<Catmandu::Searchable>

=cut

