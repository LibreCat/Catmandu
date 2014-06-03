package Catmandu::Cmd::config;

use namespace::clean;
use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu::Util qw(data_at);
use Catmandu;

sub command_opt_spec {
    (
        [ "path-prefix=s", "" ],
    );
}

sub description {
    <<EOS;
examples:

# export config to JSON
catmandu config
# or any other Catmandu::Exporter
catmandu config to YAML --fix 'delete_field(password)'
# export only part of the config file
catmandu config my.prefix to CSV
EOS
}

sub command {
    my ($self, $opts, $args) = @_;
    my $path;
    if (@$args == 1 || (@$args > 1 && $args->[1] eq 'to')) {
        $path = shift @$args;
    }
    my $into_args = [];
    my $into_opts = {};
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

    my $into = Catmandu->exporter($into_args->[0], $into_opts);
    $into->add(defined $path ?
        data_at($path, Catmandu->config) :
        Catmandu->config);
    $into->commit;
}

1;

=head1 NAME

Catmandu::Cmd::config - export the Catmandu config
