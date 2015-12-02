package Catmandu::Cmd::config;

use Catmandu::Sane;

our $VERSION = '0.9505';

use parent 'Catmandu::Cmd';
use Catmandu::Util qw(data_at);
use Catmandu;
use namespace::clean;

sub command {
    my ($self, $opts, $args) = @_;
    my $path;
    my $into_args = [];
    my $into_opts = {};
    my $into;

    if (@$args == 1 || (@$args > 1 && $args->[1] eq 'to')) {
        $path = shift @$args;
    }

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
    } else {
        $into = Catmandu->exporter('JSON', pretty => 1);
    }

    $into->add(defined $path ?
            data_at($path, Catmandu->config) :
        Catmandu->config);
    $into->commit;
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
