package Catmandu::Cmd::info;

use Catmandu::Sane;

our $VERSION = '1.0601';

use parent 'Catmandu::Cmd';
use Catmandu;
use Catmandu::Util qw(pod_section);
use namespace::clean;

sub command_opt_spec {
    (
        ["all",         "show all module on this server"],
        ["exporters",   "show all Catmandu exporters"],
        ["importers",   "show all Catmandu importers"],
        ["fixes",       "show all Catmandu fixes"],
        ["stores",      "show all Catmandu stores"],
        ["validators",  "show all Catmandu validators"],
        ["namespace=s", "search by namespace"],
        ["max_depth=i", "maximum depth to search for modules"],
        [
            "inc=s@",
            'override included directories (defaults to @INC)',
            {default => [@INC]}
        ],
        ["verbose|v",     ""],
        ["fix=s@",        ""],
        ["var=s%",        ""],
        ["preprocess|pp", ""],
    );
}

sub _add_about {
    my $item = $_[0];
    my $name = pod_section($item->{file}, 'NAME');
    $name =~ s/[^-]+(\s*-?\s*)?//;
    $name =~ s/\n/ /mg;
    chomp $name;
    $item->{about} = $name;
    $item;
}

sub command {
    my ($self, $opts, $args) = @_;
    my $verbose = $opts->verbose;

    if (defined $opts->{namespace}) {
    }
    elsif ($opts->{all}) {
        delete $opts->{all};
    }
    elsif ($opts->{exporters}) {
        delete $opts->{exporters};
        $opts->{namespace} = 'Catmandu::Exporter';
    }
    elsif ($opts->{importers}) {
        delete $opts->{importers};
        $opts->{namespace} = 'Catmandu::Importer';
    }
    elsif ($opts->{fixes}) {
        delete $opts->{fixes};
        $opts->{namespace} = 'Catmandu::Fix';
    }
    elsif ($opts->{stores}) {
        delete $opts->{stores};
        $opts->{namespace} = 'Catmandu::Store';
    }
    elsif ($opts->{validators}) {
        delete $opts->{stores};
        $opts->{namespace} = 'Catmandu::Validator';
    }
    else {
        $opts->{namespace} = [qw(Catmandu)];
    }

    my ($from_args, $from_opts, $into_args, $into_opts)
        = $self->_parse_options($args);

    for my $key (qw(inc namespace max_depth)) {
        $from_opts->{$key} = $opts->$key if defined $opts->$key;
    }

    my $from = Catmandu->importer('Modules', $from_opts)->tap(\&_add_about);

    if (@$into_args || %$into_opts) {
        if ($opts->fix) {
            $from = $self->_build_fixer($opts)->fix($from);
        }

        my $into = Catmandu->exporter($into_args->[0], $into_opts);
        $into->add_many($from);
        $into->commit;
    }
    else {
        my $cols = [qw(name version about)];
        push @$cols, 'file' if $opts->verbose;
        $from->format(cols => $cols);
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::info - list installed Catmandu modules

=head1 DESCRIPTION

This L<Catmandu::Cmd> uses L<Catmandu::Importer::Modules> to list all modules.
By default modules are listed in tabular form, like L<Catmandu::Exporter::Table>.

=head1 EXAMPLES

  catmandu info --exporters
  catmandu info --importers
  catmandu info --fixes
  catmandu info --stores
  catmandu info --validators
  catmandu info --namespace=Catmandu
  catmandu info --all

  # export list of exporter modules to JSON
  catmandu info --exporters to JSON

=cut
