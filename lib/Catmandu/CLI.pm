package Catmandu::CLI;
use Catmandu::Sane;
use Catmandu::Util qw(load_package);
use App::Cmd::Setup -app;
use FindBin;
use File::Spec;
use Cwd qw(realpath);

sub default_appdir { state $default_appdir = realpath(File::Spec->catdir($FindBin::Bin, '..')) }

sub plugin_search_path { 'Catmandu::Cmd' }

sub global_opt_spec {
    (
        ['environment=s', "application environment (default is development)"],
        ['appdir=s', "application directory (default is cwd)"],
        ['confdir=s', "application conf directory (default is appdir)"],
    );
}

# overload run to read the global options before
# the App::Cmd object is created
sub run {
  my ($class) = @_;

  my ($global_opts, $argv) = $class->_process_args(\@ARGV, $class->_global_option_processing_params);

  $ENV{DANCER_APPDIR} ||= $global_opts->{appdir} || $class->default_appdir;
  $ENV{DANCER_CONFDIR} ||= $global_opts->{confdir} if $global_opts->{confdir};
  $ENV{DANCER_ENVIRONMENT} ||= $global_opts->{environment} if $global_opts->{environment};

  load_package('Dancer')->import(':script');

  my $self = $class->new;

  $self->set_global_options($global_opts);

  my ($cmd, $opts, @args) = $self->prepare_command(@$argv);

  $self->execute_command($cmd, $opts, @args);
}

1;
