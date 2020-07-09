package Catmandu::Cmd::convert;

use Catmandu::Sane;

our $VERSION = '1.2013';

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
        [
            "id-file=s",
            "A line-delimited file containing the id's to include in the conversion. Other records will be ignored."
        ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts, $into_args, $into_opts)
        = $self->_parse_options($args);

    my $from = Catmandu->importer($from_args->[0], $from_opts);
    my $into = Catmandu->exporter($into_args->[0], $into_opts);

    if ($opts->id // $opts->id_file) {
        my $id_map = {};
        if (my $ids = $opts->id) {
            $id_map->{$_} = 1 for @$ids;
        }
        else {
            Catmandu->importer('Text', file => $opts->id_file)->each(
                sub {
                    $id_map->{$_[0]->{text}} = 1;
                }
            );
        }
        $from = $from->select(
            sub {defined $_[0]->{_id} && exists $id_map->{$_[0]->{_id}}});
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
        say STDERR $n == 1 ? "converted 1 item" : "converted $n items";
        say STDERR "done";
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::convert - convert items

=head1 EXAMPLES

  catmandu convert <IMPORTER> <OPTIONS> to <EXPORTER> <OPTIONS>

  cat books.json | catmandu convert JSON to CSV --fields id,title

  catmandu help importer JSON
  catmandu help exporter YAML

=cut
