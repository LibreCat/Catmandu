package Catmandu::Cmd::copy;

use Catmandu::Sane;

our $VERSION = '1.00_03';

use parent 'Catmandu::Cmd';
use Catmandu;
use namespace::clean;

sub command_opt_spec {
    (
        [ "verbose|v", "" ],
        [ "fix=s@", "" ],
        [ "start=i", "" ],
        [ "limit=i", "" ],
        [ "total=i", "" ],
        [ "cql-query|q=s", "" ],
        [ "query=s", "" ],
        [ "delete", "delete existing objects first" ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts, $into_args, $into_opts) = $self->_parse_options($args);

    my $from_bag = delete $from_opts->{bag};
    my $from = Catmandu->store($from_args->[0], $from_opts)->bag($from_bag);
    my $into_bag = delete $into_opts->{bag};
    my $into = Catmandu->store($into_args->[0], $into_opts)->bag($into_bag);

    if ($opts->query // $opts->cql_query) {
        $self->usage_error("Bag isn't searchable") unless $from->can('searcher');
        $from = $from->searcher(
            cql_query => $opts->cql_query,
            query     => $opts->query,
            start     => $opts->start,
            total     => $opts->total,
            limit     => $opts->limit,
        );
    } elsif ($opts->start // $opts->total) {
        $from = $from->slice($opts->start, $opts->total);
    }
    if ($opts->fix) {
        $from = Catmandu->fixer($opts->fix)->fix($from);
    }
    if ($opts->verbose) {
        $from = $from->benchmark;
    }

    if ($opts->delete) {
        $into->delete_all;
        $into->commit;
    }

    my $n = $into->add_many($from);
    $into->commit;
    if ($opts->verbose) {
        say STDERR $n ==1 ? "copied 1 object" : "copied $n objects";
        say STDERR "done";
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::copy - copy objects to another store

=head1 EXAMPLES

  catmandu copy <STORE> <OPTIONS> to <STORE> <OPTIONS>

  catmandu copy MongoDB --database_name items --bag book to \
                ElasticSearch --index_name items --bag book

  catmandu help store MongoDB
  catmandu help store ElasticSearch

=cut
