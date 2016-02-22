package Catmandu::Cmd::convert;

use Catmandu::Sane;

our $VERSION = '1.00';

use parent 'Catmandu::Cmd';
use Catmandu;
use namespace::clean;

sub command_opt_spec {
    (
        [ "verbose|v", "" ],
        [ "fix=s@", "" ],
        [ "start=i", "" ],
        [ "total=i", "" ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts, $into_args, $into_opts) = $self->_parse_options($args);

    my $from = Catmandu->importer($from_args->[0], $from_opts);
    my $into = Catmandu->exporter($into_args->[0], $into_opts);

    if ($opts->start // $opts->total) {
        $from = $from->slice($opts->start, $opts->total);
    }
    if ($opts->fix) {
        $from = Catmandu->fixer($opts->fix)->fix($from);
    }
    if ($opts->verbose) {
        $from = $from->benchmark;
    }

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
