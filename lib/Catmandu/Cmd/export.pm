package Catmandu::Cmd::export;

use Catmandu::Sane;

our $VERSION = '1.2013';

use parent 'Catmandu::Cmd';
use Catmandu;
use Catmandu::ArrayIterator;
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
        ["id=s@",          ""],
        ["id-file=s", "A line-delimited file containing the id's to export."],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts, $into_args, $into_opts)
        = $self->_parse_options($args);

    my $from_bag = delete $from_opts->{bag};
    my $from = Catmandu->store($from_args->[0], $from_opts)->bag($from_bag);
    my $into = Catmandu->exporter($into_args->[0], $into_opts);

    if ($opts->id_file) {
        my $bag = $from;
        $from = Catmandu->importer('Text', file => $opts->id_file)
            ->map(sub {$bag->get($_[0]->{text})});
    }
    elsif (my $ids = $opts->id) {
        my $bag = $from;
        $from = Catmandu::ArrayIterator->new([map {$bag->get($_)} @$ids]);
    }
    elsif ($opts->query // $opts->cql_query // $opts->sort
        // $opts->sru_sortkeys)
    {
        $self->usage_error("Bag isn't searchable")
            if !$from->does('Catmandu::Searchable');
        $self->usage_error("Bag isn't CQL searchable")
            if ($opts->cql_query // $opts->sru_sortkeys)
            && !$from->does('Catmandu::CQLSearchable');
        $from = $from->searcher(
            cql_query    => $opts->cql_query,
            query        => $opts->query,
            sru_sortkeys => $opts->sru_sortkeys,
            sort         => $opts->sort,
            start        => $opts->start,
            total        => $opts->total,
            limit        => $opts->limit,
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

    my $n = $into->add_many($from);
    $into->commit;
    if ($opts->verbose) {
        say STDERR $n == 1 ? "exported 1 item" : "exported $n items";
        say STDERR "done";
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::export - export items from a store

=head1 EXAMPLES

  catmandu export <STORE> <OPTIONS> to <EXPORTER> <OPTIONS>

  catmandu export MongoDB --database-name items --bag book to YAML

  catmandu export ElasticSearch --bag book --sru-sortkeys 'title,,1' --cql-query '(title = "test")'

  catmandu help store MongoDB
  catmandu help exporter YAML

=cut
