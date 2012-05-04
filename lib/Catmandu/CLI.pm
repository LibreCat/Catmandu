package Catmandu::CLI;
use Catmandu::Sane;
use App::Cmd::Setup -app;
use Catmandu ();

sub plugin_search_path { 'Catmandu::Cmd' }

sub global_opt_spec {
    (
        ['load_path|L=s@', ""],
    );
}

# overload run to read the global options before
# the App::Cmd object is created
sub run {
    my ($class) = @_;

    my ($global_opts, $argv) = $class->_process_args([@ARGV], $class->_global_option_processing_params);

    my $load_path = $global_opts->{load_path};
    Catmandu->load(@$load_path);

    my $self = $class->new;
    $self->set_global_options($global_opts);
    my ($cmd, $opts, @args) = $self->prepare_command(@$argv);
    $self->execute_command($cmd, $opts, @args);
}

1;
