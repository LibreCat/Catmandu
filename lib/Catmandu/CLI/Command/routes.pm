package Catmandu::CLI::Command::routes;
use Catmandu::Sane;
use Catmandu::Util qw(load_package);
use parent qw(
    Catmandu::CLI::Command
);

sub command_opt_spec {
    (
        [ "app|a=s", "a Catmandu::App. can also be the first argument" ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my $app = $args->[0] || $opts->{app};
    load_package($app);
    print $app->inspect_routes;
}

no Catmandu::Util;
1;

=head1 NAME

Catmandu::CLI::Command::routes - inspect a Catmandu::App's routes
