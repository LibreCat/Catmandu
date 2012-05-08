package Catmandu::Cmd::data;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Time::HiRes qw(gettimeofday tv_interval);
use Catmandu qw(:all);
use Catmandu::Fix;

sub command_opt_spec {
    (
        [ "from-store=s", "",    { default => Catmandu->default_store } ],
        [ "from-importer=s", "", { default => 'JSON' } ],
        [ "from-bag=s", "" ],
        [ "count", "" ],
        [ "into-exporter=s", "", { default => 'JSON' } ],
        [ "into-store=s", "",    { default => Catmandu->default_store } ],
        [ "into-bag=s", "" ],
        [ "start=i", "" ],
        [ "limit=i", "" ],
        [ "total=i", "" ],
        [ "cql-query|q=s", "" ],
        [ "query=s", "" ],
        [ "fix=s@", "fix expression(s) or fix file(s)" ],
        [ "replace", "" ],
        [ "verbose|v", "" ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my $from_opts = {};
    my $into_opts = {};
    for (my $i = 0; $i < @$args; $i++) {
        my $arg = $args->[$i];
        if (my ($for, $key) = $arg =~ /^--(from|into)-([\w\-]+)$/) {
            if (my $val = $args->[++$i]) {
                $key =~ s/-/_/g;
                ($for eq 'from' ? $from_opts : $into_opts)->{$key} = $val;
            }
        }
    }

    my $from;
    my $into;

    if ($opts->from_bag) {
        $from = store($opts->from_store, $from_opts)->bag($opts->from_bag)
    } else {
        $from = importer($opts->from_importer, $from_opts);
    }

    if ($opts->query || $opts->cql_query) {
        $self->usage_error("Bag isn't searchable") unless $from->can('searcher');
        $from = $from->searcher(
            cql_query => $opts->cql_query,
            query     => $opts->query,
            limit     => $opts->limit,
        );
    }

    if ($opts->start || defined $opts->total) {
        $from = $from->slice($opts->start, $opts->total);
    }

    if ($opts->count) {
        return say $from->count;
    }

    if ($opts->into_bag) {
        $into = store($opts->into_store, $into_opts)->bag($opts->into_bag);
    } else {
        $into = exporter($opts->into_exporter, $into_opts);
    }

    if (my $fix = $opts->fix) {
        $from = Catmandu::Fix->new(fixes => $fix)->fix($from);
    }

    if ($opts->replace && $into->can('delete_all')) {
        $into->delete_all;
    }

    my $v = $opts->verbose;
    my $n = 0;

    if ($v) {
        my $t = [gettimeofday];
        $from = $from->tap(sub {
            if (++$n % 100 == 0) {
                printf STDERR "added %9d (%d/sec)\n", $n, $n/tv_interval($t);
            }
        });
    }

    $n = $into->add_many($from);
    $into->commit;

    if ($v) {
        say STDERR $n == 1
            ? "added 1 object"
            : "added $n objects";
        say STDERR "done";
    }
}

1;

=head1 NAME

Catmandu::Cmd::data - store, index, search, import, export or convert objects
