package Catmandu::CLI::Command::export;
use Catmandu::Sane;
use Catmandu::Util qw(load_package);
use parent qw(
    Catmandu::CLI::Command
);

sub command_opt_spec {
    (
        [ "from|F=s", "the Store class to use" ],
        [ "from-arg|f=s%", "pass args to the Store constructor", {default => {}} ],
        [ "fix=s@", "fixes or paths to a fix file" ],
        [ "to|T=s", "the Export class to use" ],
        [ "to-arg|t=s%", "pass args to the Export constructor", {default => {}} ],
        [ "pretty", "pretty print objects" ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my $from = load_package($opts->{from}, 'Catmandu::Store');
    my $to = load_package($opts->{to}, 'Catmandu::Export');

    if (my $arg = shift @$args and my $key = $to->default_attribute) {
        $opts->{to_arg}{$key} = $arg;
    }

    $opts->{to_arg}{pretty} = 1 if $opts->{pretty};

    $from = $from->new($opts->{from_arg});
    $to = $to->new($opts->{to_arg});

    if (my $fix = $opts->{fix}) {
        $from = load_package('Catmandu::Fixer')->new(@$fix)->fix($from);
    }

    $to->dump($from);
}

no Catmandu::Util;
1;

=head1 NAME

Catmandu::CLI::Command::export - export data
