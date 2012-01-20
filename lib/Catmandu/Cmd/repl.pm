package Catmandu::Cmd::repl;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu::Util qw(load_package);

my $INIT = <<PERL;
use Catmandu::Sane;
use Catmandu qw(:all);
use Dancer   qw(:syntax config);
PERL

sub command_opt_spec {
    ();
}

sub command {
    my ($self, $opts, $args) = @_;

    my $repl = load_package('Devel::REPL')->new;

    $repl->load_plugin($_) for qw(LexEnv DDC Packages Commands MultiLine::PPI Colors);
    $repl->current_package('main');
    $repl->eval($INIT);
    $repl->run;
}

1;

=head1 NAME

Catmandu::Cmd::repl - interactive shell
