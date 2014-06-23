package Catmandu::Cmd::importers;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu::Importer::Modules;

sub command_opt_spec {
    (
        ["inc=s@", 'override included directories (defaults to @INC)', {default => [@INC]}],
        ["verbose|v", ""]
    );
}

sub command {
    my ($self, $opts, $args) = @_;
    my $verbose = $opts->verbose;
    my $from_opts = {
        namespace => 'Catmandu::Importer'
    };
    for my $key (qw(inc)) {
        $from_opts->{$key} = $opts->$key if defined $opts->$key;
    }
    my $from = Catmandu::Importer::Modules->new($from_opts);

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

Catmandu::Cmd::importers - list installed Catmandu importers

=head1 DESCRIPTION

This L<Catmandu::Cmd> uses L<Catmandu::Importer::Modules> to list all
modules in namespace L<Catmandu::Importer>.

=cut

1;
