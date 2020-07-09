package Catmandu::Cmd::count;

use Catmandu::Sane;

our $VERSION = '1.2013';

use parent 'Catmandu::Cmd';
use Catmandu;
use namespace::clean;

sub command_opt_spec {
    (["cql-query|q=s", ""], ["query=s", ""],);
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts) = $self->_parse_options($args);

    my $from_bag = delete $from_opts->{bag};
    my $from = Catmandu->store($from_args->[0], $from_opts)->bag($from_bag);

    if ($opts->query // $opts->cql_query) {
        $self->usage_error("Bag isn't searchable")
            unless $from->can('searcher');
        $from = $from->searcher(
            cql_query => $opts->cql_query,
            query     => $opts->query,
        );
    }

    say $from->count;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::count - count the number of items in a bag

=head1 EXAMPLES

  catmandu count <STORE> <OPTIONS>

  catmandu count ElasticSearch --index-name shop --bag products \
                               --query 'brand:Acme'

  catmandu help store ElasticSearch

=head1 SEE ALSO

To count the number of items from an importer, use L<Catmandu::Exporter::Count>.

=cut
