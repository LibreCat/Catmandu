package Catmandu::Cmd::config;

use Catmandu::Sane;

our $VERSION = '1.2013';

use parent 'Catmandu::Cmd';
use Catmandu::Util::Path qw(as_path);
use Catmandu;
use namespace::clean;

sub command_opt_spec {
    (["fix=s@", ""], ["var=s%", ""], ["preprocess|pp", ""],);
}

sub command {
    my ($self, $opts, $args) = @_;
    my $from;
    my $into;

    my ($from_args, $from_opts, $into_args, $into_opts)
        = $self->_parse_options($args);

    if (@$from_args) {
        $from = as_path($from_args->[0])->getter->(Catmandu->config);
    }
    else {
        $from = Catmandu->config;
    }

    if (@$into_args || %$into_opts) {
        $into = Catmandu->exporter($into_args->[0], $into_opts);
    }
    else {
        $into = $self->_default_exporter;
    }

    if ($opts->fix) {
        $from = $self->_build_fixer($opts)->fix($from);
    }

    $into->add($from);
    $into->commit;
}

sub _default_exporter {
    Catmandu->exporter('JSON', pretty => 1, array => 0);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::config - export the Catmandu config

=head1 EXAMPLES

  # export config to JSON
  catmandu config
  # or any other Catmandu::Exporter
  catmandu config to YAML --fix 'delete_field(password)'
  # export only part of the config file
  catmandu config my.prefix to CSV

=cut
