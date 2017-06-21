package Catmandu::Cmd::convert;

use Catmandu::Sane;

our $VERSION = '1.06';

use parent 'Catmandu::Cmd';
use Catmandu;
use Catmandu::Util qw(array_includes);
use namespace::clean;

sub command_opt_spec {
    (
        ["verbose|v",     ""],
        ["fix=s@",        ""],
        ["var=s%",        ""],
        ["preprocess|pp", ""],
        ["start=i",       ""],
        ["total=i",       ""],
        ["id=s@",         ""],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts, $into_args, $into_opts)
        = $self->_parse_options($args);

    my $from = Catmandu->importer($from_args->[0], $from_opts);
    my $into = Catmandu->exporter($into_args->[0], $into_opts);

    if (my $ids = $opts->id) {
        $from = $from->select(sub {array_includes($ids, $_[0]->{_id})});
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
