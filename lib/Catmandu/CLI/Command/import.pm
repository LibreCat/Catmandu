package Catmandu::CLI::Command::import;
use Catmandu::Sane;
use Catmandu::Util qw(load_package);
use Time::HiRes qw(gettimeofday tv_interval);
use parent qw(
    Catmandu::CLI::Command
);

sub command_opt_spec {
    (
        [ "from-import|from|F=s", "", {implies => {from_ns => 'Catmandu::Import'}} ],
        [ "from-store=s", "", {implies => {from_ns => 'Catmandu::Store'}}],
        [ "from-arg|f=s%", "", {default => {}} ],
        [ "start=i", "", {default => 0} ],
        [ "limit=i", "" ],
        [ "fix=s@", "fixes or paths to a fix file" ],
        [ "to-store|to|T=s", "", {implies => {to_ns => 'Catmandu::Store'}} ],
        [ "to-index=s", "", {implies => {to_ns => 'Catmandu::Index'}} ],
        [ "to-arg|t=s%", "", {default => {}} ],
        [ "verbose|v", "verbose output" ],
        [ "from_ns", "", {hidden => 1} ],
        [ "to_ns", "", {hidden => 1} ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my $from = load_package($opts->{from_store} || $opts->{from_import}, $opts->{from_ns});
    my $to = load_package($opts->{to_index} || $opts->{to_store}, $opts->{to_ns});

    $from = $from->new($opts->{from_arg});
    $to = $to->new($opts->{to_arg});

    if (my $fix = $opts->{fix}) {
        $from = load_package('Catmandu::Fixer')->new(@$fix)->fix($from);
    }

    my $verbose = $opts->{verbose};
    my $start = $opts->{start};
    my $limit = $opts->{limit};
    my $t = [gettimeofday];
    my $n = 0;
    my $i = 0;

    $from->each(sub {
        if ($i < $start) {
            $i++;
        } else {
            $n++;
            $to->save($_[0]);
            if ($verbose and $n % 100 == 0) {
                say sprintf "importing $n objects @ %d obj/sec", $n/tv_interval($t);
            }
            if (defined $limit and $n == $limit) {
                goto STOP_ITERATION;
            }
        }
    });

    STOP_ITERATION:

    if ($to->can('commit')) {
        if ($verbose) {
            say STDERR "committing";
        }
        $to->commit;
    }

    if ($verbose) {
        say STDERR $n > 1
            ? "imported $n objects"
            : "imported 1 object";
    }
}

no Catmandu::Util;
no Time::HiRes;
1;

=head1 NAME

Catmandu::CLI::Command::import - import data
