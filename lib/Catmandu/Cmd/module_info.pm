package Catmandu::Cmd::module_info;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use List::Util qw(sum);
use Catmandu;

sub command_opt_spec {
    (
        ["namespace=s", "namespace"],
        ["max_depth=i", "maximum depth to search for modules"],
        ["inc=s@", 'override included directories (defaults to @INC)', {default => [@INC]}],
        ["verbose|v", "include package information"]
    );
}

sub command {
    my ($self, $opts, $args) = @_;
    my $verbose = $opts->verbose;
    my $from_opts = {};
    for my $key (qw(namespace max_depth inc)) {
        $from_opts->{$key} = $opts->$key if defined $opts->$key;
    }
    my $from = Catmandu->importer('ModuleInfo', $from_opts);

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
        my $col_sep = " | ";
        my @cols = qw(name version);
        push @cols, 'file' if $opts->verbose;
        my @col_lengths = map length, @cols;
        my $rows = $from->map(sub {
            my $data = $_[0];
            my $row = [];
            for (my $i = 0; $i < @cols; $i++) {
                my $col = $data->{$cols[$i]} // "";
                my $len = length $col;
                $col_lengths[$i] = $len if $len > $col_lengths[$i];
                push @$row, $col;
            }
            $row;
        })->to_array;
        my $longest_row = sum(@col_lengths) + (length($col_sep) * (scalar(@cols) - 1));
        my @indices = 0 .. @cols-1;
        my $pattern = join($col_sep, map { "%-$col_lengths[$_]s" } @indices)."\n";
        printf $pattern, @cols;
        print '=' x $longest_row;
        print "\n";
        for my $row (@$rows) {
            printf $pattern, @$row;
        }
    }
}

1;

=head1 NAME

Catmandu::Cmd::module_info - list available packages in a given namespace

=head1 SEE ALSO

    L<Catmandu::Importer::ModuleInfo>

=cut
