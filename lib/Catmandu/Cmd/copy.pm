package Catmandu::Cmd::copy;

use Catmandu::Sane;

our $VERSION = '1.0604';

use parent 'Catmandu::Cmd';
use Catmandu;
use namespace::clean;

sub command_opt_spec {
    (
        ["verbose|v",      ""],
        ["fix=s@",         ""],
        ["var=s%",         ""],
        ["preprocess|pp",  ""],
        ["start=i",        ""],
        ["limit=i",        ""],
        ["total=i",        ""],
        ["cql-query|q=s",  ""],
        ["query=s",        ""],
        ["sru-sortkeys=s", ""],
        ["sort=s",         ""],
        ["delete",         "delete existing objects first"],
        ["transaction|tx", "wrap in a transaction"],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts, $into_args, $into_opts)
        = $self->_parse_options($args);

    my $from_bag = delete $from_opts->{bag};
    my $from = Catmandu->store($from_args->[0], $from_opts)->bag($from_bag);
    my $into_bag = delete $into_opts->{bag};
    my $into = Catmandu->store($into_args->[0], $into_opts)->bag($into_bag);

    if ($opts->query // $opts->cql_query) {
        $self->usage_error("Bag isn't searchable")
            unless $from->can('searcher');
        $from = $from->searcher(
            cql_query => $opts->cql_query,
            query     => $opts->query,
            start     => $opts->start,
            total     => $opts->total,
            limit     => $opts->limit,
        );
    }
    elsif ($opts->start // $opts->total) {
        $from = $from->slice($opts->start, $opts->total);
    }
    if ($opts->fix) {
        $from = $self->_build_fixer($opts)->fix($from);
    }
    if ($opts->verbose) {
        $from = $from->benchmark;
    }

    my $tx = sub {
        if ($opts->delete) {
            $into->delete_all;
            $into->commit;
        }

        my $n = $into->add_many($from);
        $into->commit;
        if ($opts->verbose) {
            say STDERR $n == 1 ? "copied 1 object" : "copied $n objects";
            say STDERR "done";
        }
    };

    if ($opts->transaction) {
        $self->usage_error("Bag isn't transactional")
            if !$into->does('Catmandu::Transactional');
        $into->transaction($tx);
    }
    else {
        $tx->();
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::copy - copy objects from one store to another

=head1 EXAMPLES

  catmandu copy <STORE> <OPTIONS> to <STORE> <OPTIONS>

  catmandu copy MongoDB --database_name items --bag book to \
                ElasticSearch --index_name items --bag book

  catmandu help store MongoDB
  catmandu help store ElasticSearch

=cut
