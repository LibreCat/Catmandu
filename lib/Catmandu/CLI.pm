package Catmandu::CLI;

use Catmandu::Sane;
use App::Cmd::Setup -app;
use Catmandu::Util;
use Log::Any::Adapter;
use Catmandu;

sub VERSION {
    $Catmandu::VERSION;
}

sub plugin_search_path { 'Catmandu::Cmd' }

sub global_opt_spec {
    (
        ['load_path|L=s@', ""],
        ['lib_path|I=s@', ""],
        ['debug|d',""],
    );
}

# overload run to read the global options before
# the App::Cmd object is created
sub run {
    my ($class) = @_;

    my ($global_opts, $argv) = $class->_process_args([@ARGV], $class->_global_option_processing_params);

    my $load_path = $global_opts->{load_path} || [];
    my $lib_path = $global_opts->{lib_path} || [];
    my $debug = $global_opts->{debug};

    Catmandu->load(@$load_path);

    if (@$lib_path) {
        Catmandu::Util::use_lib(@$lib_path);
    }

    if (defined $debug) {
        Log::Any::Adapter->set('Stderr');
    }

    my $self = ref $class ? $class : $class->new;
    $self->set_global_options($global_opts);
    my ($cmd, $opts, @args) = $self->prepare_command(@$argv);

    eval {
        $self->execute_command($cmd, $opts, @args);
    };
    if ($@) {
        if ($@ =~ /^Can't locate Catmandu\/Importer/ && $ARGV[1] eq 'help') {
            print STDERR "You probably mean:\n\n\t$0 $ARGV[1] $ARGV[0]\n";
            return undef;
        }
        elsif ($@ =~ /Can't locate Catmandu\/(Importer|Exporter|Store)\/([^\.]+)/) {
            print STDERR "Can't find:\n\n\tCatmandu::$1\::$2\n\nin your installation. Or a\n\n\t$2\n\nin your catmandu.yml\n";
            return undef;
        }
        elsif ($@ =~ /unknown store default/) {
            print STDERR "You need to provide the type of a Store or define one in your catmandu.yml file.\n";
            return undef;
        }
        elsif ($@ =~ /can't open "(.*)" for reading/) {
            print STDERR "Can't find this Fix (file):\n\n\t$1\n\nDid you spell it correctly?\n";
            return undef;
        }
        else {
            die $@;
        }
    }
    
    1;
}

1;
