package Catmandu::CLI;

=head1 NAME

Catmandu::CLI - The App::Cmd application class for the catmandu command line script

=head1 SEE ALSO

L<catmandu>

=cut

use Catmandu::Sane;
use App::Cmd::Setup -app;
use Catmandu::Util;
use Catmandu;
use Log::Any::Adapter;

sub VERSION {
    $Catmandu::VERSION;
}

sub default_command { 'commands' }

sub plugin_search_path { 'Catmandu::Cmd' }

sub global_opt_spec {
    (
        ['debug|D:i',""],
        ['load_path|L=s@', ""],
        ['lib_path|I=s@', ""]
    );
}

sub default_log4perl_config {
    my $level    = shift // 'DEBUG';
    my $appender = shift // 'STDERR';

    my $config =<<EOF;
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
    \$config
}

sub setup_debugging {
    my %LEVELS = ( 1 => 'WARN' , 2 => 'INFO' , 3 => 'DEBUG');
    my $debug = shift;
    my $level = $LEVELS{$debug} // 'WARN';
    my $load_from;

    try {
        my $log4perl_pkg   = Catmandu::Util::require_package('Log::Log4perl');
        my $logany_adapter = Catmandu::Util::require_package('Log::Any::Adapter::Log4perl');
        my $config         = Catmandu->config->{log4perl};

        if (defined $config) {
            if ($config =~ /^\S+$/) {
                Log::Log4perl::init( $config ) ;
                $load_from = "file: $config";
            }
            else {
                Log::Log4perl::init( \$config ) ;
                $load_from = "string: <defined in catmandu.yml>";
            }
        }
        else {
            Log::Log4perl::init( default_log4perl_config($level, 'STDERR') );
            $load_from = "string: <defined in " . __PACKAGE__ . ">";
        }

        Log::Any::Adapter->set('Log4perl');
    } catch {
        print STDERR <<EOF;

Oops! Debugging tools not available on this platform

Try to install Log::Log4perl and Log::Any::Adapter::Log4perl

Hint: cpan Log::Log4perl Log::Any::Adapter::Log4perl
EOF
        exit(2);
    };

    Catmandu->log->warn("debug activated - level $level - config load from $load_from");
}

# overload run to read the global options before
# the App::Cmd object is created
sub run {
    my ($class) = @_;

    my ($global_opts, $argv) = $class->_process_args([@ARGV], $class->_global_option_processing_params);

    my $load_path = $global_opts->{load_path} || [];
    my $lib_path  = $global_opts->{lib_path} || [];

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
    } catch {
        if (ref $_ eq 'Catmandu::NoSuchPackage') {
            my $message = $_->message;

            if ($message =~ /Catmandu::Importer::help/) {
                say STDERR "Oops! Did you mean 'catmandu $ARGV[1] $ARGV[0]'?";
            }
            elsif ($message =~ /Catmandu::Importer::(\S+)/) {
                say STDERR "Oops! Can not find the importer '$1' in your configuration file or Catmandu::Importer::$1 is not installed.";
            }
            elsif ($message =~ /Catmandu::Exporter::(\S+)/) {
                say STDERR "Oops! Can not find the exporter '$1' in your configuration file or Catmandu::Exporter::$1 is not installed.";
            }
            elsif ($message =~ /Catmandu::Store::(\S+)/) {
                say STDERR "Oops! Can not find the store '$1' in your configuration file or Catmandu::Store::$1 is not installed.";
            }
            elsif ($message =~ /Catmandu::Fix::(\S+)/) {
                say STDERR "Oops! Tried to execute the fix '$1' but can't find Catmandu::Fix::$1 on your system.";
            }
            else {
                say STDERR "Oops! Failed to load $message";
            }

            goto ERROR;
        }
        elsif (ref $_ eq 'Catmandu::ParseError') {
            my $message = $_->message;
            my $source  = $_->source;

            say STDERR "Oops! Syntax error in your fixes...";
            say STDERR "\n\t$message\n";
            say STDERR "Source:\n";
            
            for (split(/\n/,$source)) {
                print STDERR "\t$_\n";
            }

            goto ERROR;
        }
        elsif (ref $_ eq 'Catmandu::FixError') {
            my $message = $_->message;
            my $data    = $_->data;
            my $fix     = $_->fix;
        
            say STDERR "Oops! One of your fixes threw an error...";
            say STDERR "Source: " . $_->fix;
            say STDERR "Error: $message";    

            use Data::Dumper;
            say STDERR "Input:\n" . Dumper($data) if defined $data;

            goto ERROR;
        }
        else {
            die $_;
        }
    };

    return 1;

    ERROR:
        return undef;
}

1;
