package Catmandu::Cmd::delete;

use Catmandu::Sane;

our $VERSION = '0.9505';

use parent 'Catmandu::Cmd';
use Catmandu;
use namespace::clean;

sub command_opt_spec {
    (
        [ "cql-query|q=s", "" ],
        [ "query=s", "" ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts) = $self->_parse_options($args);

    my $from_bag = delete $from_opts->{bag};
    my $from = Catmandu->store($from_args->[0], $from_opts)->bag($from_bag);
    if ($opts->query // $opts->cql_query) {
        $from->delete_by_query(
            cql_query => $opts->cql_query,
            query     => $opts->query,
        );
    } else {
        $from->delete_all;
    }

    $from->commit;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::delete - delete objects from a store

=head1 EXAMPLES

  catmandu delete <STORE> <OPTIONS>

  catmandu delete ElasticSearch --index-name items --bag book \
                                --query 'title:"My Rabbit"'

  catmandu help store ElasticSearch
  
=cut
