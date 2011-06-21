package Catmandu::Cmd::data;
use Catmandu::Sane;
use parent qw(Catmandu::Cmd);
use Time::HiRes qw(gettimeofday tv_interval);
use Catmandu::Iterator;
use Catmandu::Searcher;
use Catmandu::Fix;
use Catmandu;

sub command_opt_spec {
    (
        ['from' => hidden => { required => 1, one_of => [
            [ "from-store=s", "" ],
            [ "from-index=s", "" ],
            [ "from-importer=s", "" ],
        ]}],
        [ "from-arg=s@", "", { default => [] } ],
        [ "from-opt=s%", "", { default => {} } ],
        ['into' => hidden => { required => 1, one_of => [
            [ "into-store=s", "" ],
            [ "into-index=s", "" ],
            [ "into-exporter=s", "" ],
        ]}],
        [ "into-arg=s@", "", { default => [] } ],
        [ "into-opt=s%", "", { default => {} } ],
        [ "skip=i", "", { default => 0 } ],
        [ "size=i", "" ],
        [ "verbose|v", "" ],
        [ "fix=s@", "fix or fix file (repeatable)" ],
        [ "reify", "" ],
        [ "query|q=s", "" ],
        [ "pretty", "" ],
        [ "from-file=s", "" ],
        [ "from-url=s", "" ],
        [ "into-file=s", "" ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    if ($opts->from eq 'from_importer') {
        $opts->from_opt->{file}   = $opts->from_file if $opts->from_file;
        $opts->from_opt->{url}    = $opts->from_url  if $opts->from_url;
    }

    if ($opts->into eq 'into_exporter') {
        $opts->into_opt->{file}   = $opts->into_file if $opts->into_file;
        $opts->into_opt->{pretty} = 1                if $opts->pretty;
    }

    my @from_args = (@{$opts->from_arg}, %{$opts->from_opt});
    my @into_args = (@{$opts->into_arg}, %{$opts->into_opt});

    my $from;
    given ($opts->from) {
        when ('from_store')    { $from = Catmandu::new_store($opts->from_store, @from_args) }
        when ('from_index')    { $from = Catmandu::new_index($opts->from_index, @from_args) }
        when ('from_importer') { $from = Catmandu::new_importer($opts->from_importer, @from_args) }
    }

    my $into;
    given ($opts->into) {
        when ('into_store')    { $into = Catmandu::new_store($opts->into_store, @into_args) }
        when ('into_index')    { $into = Catmandu::new_index($opts->into_index, @into_args) }
        when ('into_exporter') { $into = Catmandu::new_exporter($opts->into_exporter, @into_args) }
    }

    my $v = $opts->verbose;
    my $n = 0;

    if ($opts->from eq 'from_index') {
        $from = Catmandu::Searcher->new($from, $opts->query,
            reify => $opts->reify,
            skip  => $opts->skip,
            size  => $opts->size);
    } elsif ($opts->size // $opts->skip) {
        $from = Catmandu::Iterator->new($from)->slice($opts->skip, $opts->size);
    }

    if (my $fix = $opts->fix) {
        $from = Catmandu::Fix->new(@$fix)->fix($from);
    }

    $into->add(Catmandu::Iterator->new(sub {
        my $sub = $_[0];
        my $t   = [gettimeofday];

        $from->each(sub {
            $sub->($_[0]);
            $n++;
            if ($v and $n % 100 == 0) {
                printf STDERR "added %9d objects (%d/sec)\n", $n, $n/tv_interval($t);
            }
        });
    }));

    if ($into->can('commit')) {
        say STDERR "committing" if $v;
        $into->commit;
    }

    if ($v) {
        say STDERR $n > 1
            ? "added $n objects"
            : "added 1 object";
        say STDERR "done";
    }
}

1;

=head1 NAME

Catmandu::Cmd::data - store, index, search, import, export or convert objects
