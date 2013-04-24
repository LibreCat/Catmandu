package Catmandu::Cmd::config;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu::Util qw(data_at);
use Catmandu;
use JSON ();

sub command_opt_spec {
    (
        [ "pretty!", "prettyprint", { default => 1 } ],
    );
}

sub description {
    <<EOS;
examples:

catmandu config my.nested.key
catmandu config --nopretty

options:
EOS
}

sub command {
    my ($self, $opts, $args) = @_;
    my $conf = data_at($args, Catmandu->config);
    print JSON->new->allow_nonref(1)
        ->pretty($opts->pretty ? 1 : 0)
        ->encode($conf);
}

1;

=head1 NAME

Catmandu::Cmd::config - print the Catmandu config as JSON
