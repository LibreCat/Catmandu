package Catmandu::Cmd::delete;

use Catmandu::Sane;

our $VERSION = '1.0606';

use parent 'Catmandu::Cmd';
use Catmandu;
use Catmandu::Util qw(check_able);
use namespace::clean;

sub command_opt_spec {
    (["cql-query|q=s", ""], ["query=s", ""], ["id=s@", ""],);
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts) = $self->_parse_options($args);

    my $from_bag = delete $from_opts->{bag};
    my $from = Catmandu->store($from_args->[0], $from_opts)->bag($from_bag);
    if ($opts->id) {
        $from->delete($_) for @{$opts->id};
    }
    elsif ($opts->query // $opts->cql_query) {
        check_able($from, 'delete_by_query');
        $from->delete_by_query(
            cql_query => $opts->cql_query,
            query     => $opts->query,
        );
    }
    else {
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

  
  # delete items with matching _id
  catmandu delete ElasticSearch --index-name items --bag book \
                                --id 1234 --id 2345

  # delete items matching the query
  catmandu delete ElasticSearch --index-name items --bag book \
                                --query 'title:"My Rabbit"'

  # delete all items
  catmandu delete ElasticSearch --index-name items --bag book

  catmandu help store ElasticSearch

=cut
