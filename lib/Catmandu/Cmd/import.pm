package Catmandu::Cmd::import;

use Catmandu::Sane;

our $VERSION = '1.0201';

use parent 'Catmandu::Cmd';
use Catmandu;
use namespace::clean;

sub command_opt_spec {
    (
        ["verbose|v",     ""],
        ["fix=s@",        ""],
        ["var=s%",        ""],
        ["preprocess|pp", ""],
        ["start=i",       ""],
        ["total=i",       ""],
        ["delete",        "delete existing objects first"],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my ($from_args, $from_opts, $into_args, $into_opts)
        = $self->_parse_options($args);

    my $from = Catmandu->importer($from_args->[0], $from_opts);
    my $into_bag = delete $into_opts->{bag};
    my $into = Catmandu->store($into_args->[0], $into_opts)->bag($into_bag);

    if ($opts->start // $opts->total) {
        $from = $from->slice($opts->start, $opts->total);
    }
    if ($opts->fix) {
        $from = $self->_build_fixer($opts)->fix($from);
    }
    if ($opts->verbose) {
        $from = $from->benchmark;
    }

    if ($opts->delete) {
        $into->delete_all;
        $into->commit;
    }

    my $n = $into->add_many($from);
    $into->commit;
    if ($opts->verbose) {
        say STDERR $n == 1 ? "imported 1 object" : "imported $n objects";
        say STDERR "done";
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::import - import objects into a store

=head1 EXAMPLES

  catmandu import <IMPORTER> <OPTIONS> to <STORE> <OPTIONS>

  catmandu import YAML to MongoDB --database-name items --bag book < books.yml

  catmandu help importer YAML
  catmandu help importer MongoDB

=cut
