package Catmandu::CLI::Command::start;
use Catmandu::Sane;
use Plack::Runner;
use parent qw(
    Catmandu::CLI::Command
);

sub command_opt_spec {
    (
        [ "app|a=s", "either a .psgi script to run or a Catmandu::App." .
            "defaults to app.psgi. can also be the first argument", {default => 'app.psgi'} ],
        [ "host|o=s", "the interface the TCP server binds to. defaults to *" ],
        [ "port|p=i", "the port the TCP server listens on. defaults to 5000", {default => 5000} ],
        [ "socket|S=s", "UNIX domain socket path to listen on" ],
        [ "daemonize|D", "run the server process in the background" ],
        [ "loader|L=s", "" ],
        [ "server|s=s", "PSGI server to run. defaults to HTTP::Server::PSGI" ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my $app = $args->[0] || $opts->{app};

    my @argv;

    if ($app =~ /\.psgi$/) {
        push @argv, '-a', Catmandu->file($app) || Catmandu->file('psgi', $app) || 
            confess("Can't find psgi app $app");
    } else {
        push @argv, '-e', "use $app; ${app}->psgi_app";
    }

    push @argv, map { ('-I', $_) } Catmandu->path_list('lib');
    push @argv, '-E', Catmandu->env;
    push @argv, '-p', $opts->{port}   if $opts->{port};
    push @argv, '-o', $opts->{host}   if $opts->{host};
    push @argv, '-S', $opts->{socket} if $opts->{socket};
    push @argv, '-D'                  if $opts->{daemonize};
    push @argv, '-L', $opts->{loader} if $opts->{loader};
    push @argv, '-s', $opts->{server} if $opts->{server};

    Plack::Runner->run(@argv);
}

1;

=head1 NAME

Catmandu::CLI::Command::start - start serving a PSGI app
