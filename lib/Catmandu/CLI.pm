package Catmandu::CLI;
use Catmandu::Sane;
use App::Cmd::Setup -app;
use Dancer qw(:syntax);
use File::Spec;
use Cwd qw(realpath);
use FindBin;

sub default_appdir { realpath(File::Spec->catdir($FindBin::Bin, '..')) }

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
 
  my $appdir = $global_opts->{appdir} || $ENV{DANCER_APPDIR} || $class->default_appdir;
 
  Dancer::Config::setting('confdir', $global_opts->{confdir}) if $global_opts->{confdir};
  Dancer::Config::setting('appdir',  $appdir);
  config->{environment} = $global_opts->{environment} if $global_opts->{environment};
  my ($ok, $error) = Dancer::ModuleLoader->use_lib(File::Spec->catfile($appdir, 'lib'));
  $ok or confess "unable to set libdir : $error";
  Dancer::Config::load;

  my $self = $class->new;

  $self->set_global_options($global_opts);

  my ($cmd, $opts, @args) = $self->prepare_command(@$argv);

  $self->execute_command($cmd, $opts, @args);
}

1;
