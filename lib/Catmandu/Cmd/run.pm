package Catmandu::Cmd::run;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu;
use Catmandu::Fix;

sub command_opt_spec {
    (
        [ "verbose|v", "" ],
    );
}

sub description {
    <<EOS;
examples:

catmandu run myfixes.txt

options:
EOS
}

sub command {
    my ($self, $opts, $args) = @_;
    my $fix_file = $args->[0];
    $fix_file = [\*STDIN] unless defined $fix_file;

    my $from = Catmandu->importer('Null');
    my $into = Catmandu->exporter('Null', fix => $fix_file);

    $from = $from->benchmark if $opts->verbose;
    my $n = $into->add_many($from);
    $into->commit;

    if ($opts->verbose) {
        say STDERR $n == 1 ? "converted 1 object" : "converted $n objects";
        say STDERR "done";
    }
}

1;

=head1 NAME

Catmandu::Cmd::run - run a fix command
