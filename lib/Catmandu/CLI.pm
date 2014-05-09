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
        ['lib_path|I=s@', ""],
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

    $self->execute_command($cmd, $opts, @args);
}

1;
