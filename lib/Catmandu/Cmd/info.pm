package Catmandu::Cmd::info;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu::Importer::Modules;
use Catmandu::Store::Hash;

use Data::Dumper;

sub command_opt_spec {
    (
        ["all"       , "show all module on this server"],
        ["exporters" , "show all catmandu exporters"],
        ["importers" , "show all catmandu importers"],
        ["fixes"     , "show all catmandu fixes"],
        ["stores"    , "show all catmandu stores"],
        ["namespace=s", "search by namespace"],
        ["max_depth=i", "maximum depth to search for modules"],
        ["inc=s@", 'override included directories (defaults to @INC)', {default => [@INC]}],
        ["verbose|v", ""]
    );
}

sub all_catmandu {
    my ($opts)  = @_;
    my $from = Catmandu::Store::Hash->new()->bag;

    for my $namespace (qw(Catmandu::Exporter Catmandu::Fix Catmandu::Importer Catmandu::Store)) {
        my $from_opts = { namespace => $namespace };
        for my $key (qw(inc)) {
            $from_opts->{$key} = $opts->$key if defined $opts->$key;
        }

        my $m = Catmandu::Importer::Modules->new($from_opts)->to_array;
        $from->add_many($m);
    }

    $from;
}

sub all_modules {
    my ($opts)    = @_;
    my $from_opts = {};

    for my $key (qw(inc namespace max_depth)) {
        $from_opts->{$key} = $opts->$key if defined $opts->$key;
    }

    Catmandu::Importer::Modules->new($from_opts);
}

sub command {
    my ($self, $opts, $args) = @_;
    my $verbose = $opts->verbose;
    my $from;

    if (defined $opts->{namespace}) {
        $from = all_modules($opts);
    }
    elsif ($opts->{all}) {
        delete $opts->{all};
        $from = all_modules($opts);
    }
    elsif ($opts->{exporters}) {
        delete $opts->{exporters};
        $opts->{namespace} = 'Catmandu::Exporter';
        $from = all_modules($opts);
    }
    elsif ($opts->{importers}) {
        delete $opts->{importers};
        $opts->{namespace} = 'Catmandu::Importer';
        $from = all_modules($opts);
    }
    elsif ($opts->{fixes}) {
        delete $opts->{fixes};
        $opts->{namespace} = 'Catmandu::Fix';
        $from = all_modules($opts);
    }
    elsif ($opts->{stores}) {
        delete $opts->{stores};
        $opts->{namespace} = 'Catmandu::Store';
        $from = all_modules($opts);
    }
    else {
        $from = all_catmandu($opts);
    }

    my $into_args = [];
    my $into_opts = {};
    my $into;

    if (@$args && $args->[0] eq 'to') {
        for (my $i = 1; $i < @$args; $i++) {
            my $arg = $args->[$i];
            if ($arg =~ s/^-+//) {
                $arg =~ s/-/_/g;
                if ($arg eq 'fix') {
                    push @{$into_opts->{$arg} ||= []}, $args->[++$i];
                } else {
                    $into_opts->{$arg} = $args->[++$i];
                }
            } else {
                push @$into_args, $arg;
            }
        }
    }

    if (@$into_args || %$into_opts) {
        $into = Catmandu->exporter($into_args->[0], $into_opts);
        $into->add_many($from);
        $into->commit;
    } else {
        my $cols = [qw(name version)];
        push @$cols, 'file' if $opts->verbose;
        $from->format(cols => $cols);
    }
}

=head1 NAME

Catmandu::Cmd::info - list installed Catmandu modules

=head1 DESCRIPTION

This L<Catmandu::Cmd> uses L<Catmandu::Importer::Modules> to list all modules.

=cut

1;