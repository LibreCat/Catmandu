package Catmandu::Cmd::convert;

use Catmandu::Sane;

our $VERSION = '0.9503';

use parent 'Catmandu::Cmd';
use Catmandu;
use Catmandu::Fix;
use namespace::clean;

sub command_opt_spec {
    (
        [ "verbose|v", "" ],
    );
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

    my $from = Catmandu->importer($from_args->[0], $from_opts);
    my $into = Catmandu->exporter($into_args->[0], $into_opts);

    $from = $from->benchmark if $opts->verbose;
    my $n = $into->add_many($from);
    $into->commit;
    if ($opts->verbose) {
        say STDERR $n == 1 ? "converted 1 object" : "converted $n objects";
        say STDERR "done";
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::convert - convert objects

=head1 EXAMPLES

  catmandu convert <IMPORTER> <OPTIONS> to <EXPORTER> <OPTIONS>

  cat books.json | catmandu convert JSON to CSV --fields id,title

  catmandu help importer JSON
  catmandu help exporter YAML

=cut
