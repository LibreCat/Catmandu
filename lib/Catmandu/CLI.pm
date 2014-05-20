package Catmandu::CLI;

use Catmandu::Sane;
use App::Cmd::Setup -app;
use Catmandu::Util;
use Catmandu;

sub VERSION {
    $Catmandu::VERSION;
}

sub plugin_search_path { 'Catmandu::Cmd' }

sub global_opt_spec {
    (
        ['load_path|L=s@', ""],
        ['lib_path|I=s@', ""]
    );
}

# overload run to read the global options before
# the App::Cmd object is created
sub run {
    my ($class) = @_;

    my ($global_opts, $argv) = $class->_process_args([@ARGV], $class->_global_option_processing_params);

    my $load_path = $global_opts->{load_path} || [];
    my $lib_path = $global_opts->{lib_path} || [];

    Catmandu->load(@$load_path);

    if (@$lib_path) {
        Catmandu::Util::use_lib(@$lib_path);
    }

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
