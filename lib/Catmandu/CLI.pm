package Catmandu::CLI;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Catmandu::Util qw(is_instance is_able is_string);
use Catmandu;
use Log::Any::Adapter;
use Data::Dumper;

use parent qw(App::Cmd);

sub deleted_commands {
    [
        qw(
            Catmandu::Cmd::data
            Catmandu::Cmd::exporter_info
            Catmandu::Cmd::fix_info
            Catmandu::Cmd::importer_info
            Catmandu::Cmd::module_info
            Catmandu::Cmd::move
            Catmandu::Cmd::store_info
            )
    ];
}

sub default_command {'commands'}

sub plugin_search_path {'Catmandu::Cmd'}

sub global_opt_spec {
    (['debug|D:i', ""], ['load_path|L=s@', ""], ['lib_path|I=s@', ""]);
}

sub default_log4perl_config {
    my $level    = shift // 'DEBUG';
    my $appender = shift // 'STDERR';

    my $config = <<EOF;
log4perl.category.Catmandu=$level,$appender
log4perl.categoty.Catmandu::Fix::log=TRACE,$appender

log4perl.appender.STDOUT=Log::Log4perl::Appender::Screen
log4perl.appender.STDOUT.stderr=0
log4perl.appender.STDOUT.utf8=1

log4perl.appender.STDOUT.layout=PatternLayout
log4perl.appender.STDOUT.layout.ConversionPattern=%d [%P] - %p %l %M time=%r : %m%n

log4perl.appender.STDERR=Log::Log4perl::Appender::Screen
log4perl.appender.STDERR.stderr=1
log4perl.appender.STDERR.utf8=1

log4perl.appender.STDERR.layout=PatternLayout
log4perl.appender.STDERR.layout.ConversionPattern=%d [%P] - %l : %m%n

EOF
    \$config;
}

sub setup_debugging {
    my %LEVELS = (1 => 'WARN', 2 => 'INFO', 3 => 'DEBUG');
    my $debug  = shift;
    my $level  = $LEVELS{$debug} // 'WARN';
    my $load_from;

    try {
        my $log4perl_pkg = Catmandu::Util::require_package('Log::Log4perl');
        my $logany_adapter
            = Catmandu::Util::require_package('Log::Any::Adapter::Log4perl');
        my $config = Catmandu->config->{log4perl};

        if (defined $config) {
            if ($config =~ /^\S+$/) {
                Log::Log4perl::init($config);
                $load_from = "file: $config";
            }
            else {
                Log::Log4perl::init(\$config);
                $load_from = "string: <defined in catmandu.yml>";
            }
        }
        else {
            Log::Log4perl::init(default_log4perl_config($level, 'STDERR'));
            $load_from = "string: <defined in " . __PACKAGE__ . ">";
        }

        Log::Any::Adapter->set('Log4perl');
    }
    catch {
        print STDERR <<EOF;

Oops! Debugging tools not available on this platform

Try to install Log::Log4perl and Log::Any::Adapter::Log4perl

Hint: cpan Log::Log4perl Log::Any::Adapter::Log4perl
EOF
        exit(2);
    };

    Catmandu->log->warn(
        "debug activated - level $level - config load from $load_from");
}

# overload run to read the global options before
# the App::Cmd object is created
sub run {
    my ($class) = @_;

    my ($global_opts, $argv)
        = $class->_process_args([@ARGV],
        $class->_global_option_processing_params);

    my $load_path = $global_opts->{load_path} || [];
    my $lib_path  = $global_opts->{lib_path}  || [];

    if (exists $global_opts->{debug}) {
        setup_debugging($global_opts->{debug} // 1);
    }

    if (@$lib_path) {
        Catmandu::Util::use_lib(@$lib_path);
    }

    Catmandu->load(@$load_path);

    my $self = ref $class ? $class : $class->new;
    $self->set_global_options($global_opts);
    my ($cmd, $opts, @args) = $self->prepare_command(@$argv);

    try {
        $self->execute_command($cmd, $opts, @args);
    }
    catch {
        if (is_instance $_, 'Catmandu::NoSuchPackage') {
            my $pkg_name = $_->package_name;

            if ($pkg_name eq 'Catmandu::Importer::help') {
                say STDERR "Oops! Did you mean 'catmandu $ARGV[1] $ARGV[0]'?";
            }
            elsif (my ($type, $name)
                = $pkg_name =~ /^Catmandu::(Importer|Exporter|Store)::(\S+)/)
            {
                say STDERR "Oops! Can't find the "
                    . lc($type)
                    . " '$name' in your configuration file or $pkg_name is not installed.";
            }
            elsif ($pkg_name =~ /^Catmandu::Fix::\S+/) {
                my ($fix_name) = $pkg_name =~ /([^:]+)$/;
                if ($fix_name =~ /^[a-z]/) {
                    say STDERR
                        "Oops! Tried to execute the fix '$fix_name' but can't find $pkg_name on your system.";
                }
                else {    # not a fix
                    say STDERR "Oops! Failed to load $pkg_name";
                }
            }
            else {
                say STDERR "Oops! Failed to load $pkg_name";
            }

            if (is_able $_, 'source') {
                $self->print_source($_->source);
            }

            goto ERROR;
        }
        elsif (is_instance $_, 'Catmandu::BadFixArg') {
            my $fix_name = $_->fix_name;
            my $source   = $_->source;
            say STDERR
                "Oops! The fix '$fix_name' was called with missing or wrong arguments.";
            $self->print_source($_->source);
        }
        elsif (is_instance $_, 'Catmandu::FixParseError') {
            my $message = $_->message;

            say STDERR "Oops! Syntax error in your fixes...";
            say STDERR "\n\t$message\n";
            $self->print_source($_->source);

            goto ERROR;
        }
        elsif (is_instance $_, 'Catmandu::FixError') {
            my $message = $_->message;
            my $data    = $_->data;
            my $fix     = $_->fix;

            say STDERR "Oops! One of your fixes threw an error...";
            say STDERR "Source: " . $_->fix;
            say STDERR "Error: $message";

            say STDERR "Input:\n" . Dumper($data) if defined $data;

            goto ERROR;
        }
        elsif (is_instance $_, 'Catmandu::HTTPError') {
            my $message       = $_->message;
            my $code          = $_->code;
            my $url           = $_->url;
            my $method        = $_->method;
            my $request_body  = $_->request_body;
            my $response_body = $_->response_body;

            say STDERR "Oops! Got a HTTP error...";
            say STDERR "Code: $code";
            say STDERR "Error: $message";
            say STDERR "URL: $url";
            say STDERR "Method: $method";
            say STDERR "Request headers:\n" . Dumper($_->request_headers);
            say STDERR "Request body:\n$request_body"
                if is_string $request_body;
            say STDERR "Response headers:\n" . Dumper($_->response_headers);
            say STDERR "Response body:\n$response_body"
                if is_string $response_body;

            goto ERROR;
        }
        else {
            say STDERR "Oops! $_";

            goto ERROR;
        }
    };

    return 1;

ERROR:
    return undef;
}

sub print_source {
    my ($self, $source) = @_;
    if (is_string $source) {
        say STDERR "Source:\n";
        for (split(/\n/, $source)) {
            print STDERR "\t$_\n";
        }
    }
}

sub should_ignore {
    my ($self, $cmd_class) = @_;
    for my $cmd (@{$self->deleted_commands}) {
        return 1 if $cmd_class->isa($cmd);
    }
    return;
}

1;

__END__

=pod

=head1 NAME

Catmandu::CLI - The App::Cmd application class for the catmandu command line script

=head1 SEE ALSO

L<catmandu>

=cut
