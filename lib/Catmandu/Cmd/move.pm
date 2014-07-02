package Catmandu::Cmd::move;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu;
use Catmandu::Fix;

sub command_opt_spec {
    (
        [ "verbose|v", "" ],
        [ "query|q=s", "" ],
        [ "limit=i", "" ],
    );
}

sub description {
    <<EOS;
examples:

catmandu move MongoDB --database_name items --bag book to ElasticSearch --index_name items --bag book

options:
EOS
}

sub command {
    my ($self, $opts, $args) = @_;

    my $a = my $from_args = [];
    my $o = my $from_opts = {};
    my $into_args = [];
    my $into_opts = {};

    for (my $i = 0; $i < @$args; $i++) {
        my $arg = $args->[$i];
        if ($arg eq 'to') {
            $a = $into_args;
            $o = $into_opts;
        } elsif ($arg =~ s/^-+//) {
            $arg =~ s/-/_/g;
            if ($arg eq 'fix') {
                push @{$o->{$arg} ||= []}, $args->[++$i];
            } else {
                $o->{$arg} = $args->[++$i];
            }
        } else {
            push @$a, $arg;
        }
    }

    my $from_bag = delete $from_opts->{bag};
    my $into_bag = delete $into_opts->{bag};
    my $from = Catmandu->store($from_args->[0], $from_opts)->bag($from_bag);
    my $into = Catmandu->store($into_args->[0], $into_opts)->bag($into_bag);
    if (defined $opts->query) {
        $from = $from->searcher(query => $opts->query, total => $opts->limit);
    } elsif (defined $opts->limit) {
        $from = $from->take($opts->limit);
    }

    $from = $from->benchmark if $opts->verbose;
    my $n = $into->add_many($from);
    $into->commit;
    if ($opts->verbose) {
        say STDERR $n ==1 ? "moved 1 object" : "moved $n objects";
        say STDERR "done";
    }
}

1;

=head1 NAME

Catmandu::Cmd::move - move objects to another store
