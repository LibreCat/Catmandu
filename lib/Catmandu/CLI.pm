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
        ['environment=s', "application environment"],
        ['appdir=s', "application directory (default is ".$_[0]->default_appdir.")"],
        ['confdir=s', "application config directory (default is appdir)"],
    );
}

# overload run to read the global options before
# the App::Cmd object is created
sub run {
  my ($class) = @_;

  my ($global_opts, $argv) = $class->_process_args(\@ARGV, $class->_global_option_processing_params);

  my $appdir = $global_opts->{appdir} || $ENV{DANCER_APPDIR} || $class->default_appdir;
  my $libdir = File::Spec->catdir($appdir, 'lib');

  Dancer::setting(appdir => $appdir);
  Dancer::setting(confdir => $global_opts->{confdir}) if $global_opts->{confdir};
  Dancer::setting(public => $ENV{DANCER_PUBLIC} || File::Spec->catdir($appdir, 'public'));
  Dancer::setting(views => $ENV{DANCER_VIEWS}  || File::Spec->catdir($appdir, 'views'));
  config->{environment} = $global_opts->{environment} if $global_opts->{environment};
  Dancer::ModuleLoader->use_lib($libdir);
  Dancer::Config::load;

  my $self = $class->new;

  $self->set_global_options($global_opts);

  my ($cmd, $opts, @args) = $self->prepare_command(@$argv);

  $self->execute_command($cmd, $opts, @args);
}

1;
