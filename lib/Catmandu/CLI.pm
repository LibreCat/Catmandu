package Catmandu::CLI;
use Catmandu::Sane;
use App::Cmd::Setup -app;
use Dancer qw(:syntax);
use File::Spec;
use Cwd ();

sub plugin_search_path { 'Catmandu::Cmd' }

sub global_opt_spec {
    (
        ['environment=s', "app environment"],
        ['appdir=s', "app directory (default is ".$_[0]->appdir.")"],
        ['confdir=s', "app config directory (default is appdir)"],
    );
}

my $appdir;

sub is_appdir {
    my ($class, $dir) = @_;
    -f File::Spec->catfile($dir, 'config.yml');
}

sub default_appdir {
    my ($class) = @_;
    # try script parent dir
    my ($vol, $dir, $script) = File::Spec->splitpath($0);
    $dir = Cwd::realpath(File::Spec->catdir($dir, File::Spec->updir));
    return $dir if $class->is_appdir($dir);
    # search for appdir upwards from cwd
    my @dirs = File::Spec->splitdir(my $cwd = Cwd::getcwd);
    do {
        $dir = File::Spec->catdir(@dirs);
        return $dir if $class->is_appdir($dir);
    } while (defined pop @dirs);
    # default to cwd
    $cwd;
}

sub appdir {
    $appdir //= $_[0]->default_appdir;
}

sub run_as_script {
    my ($class) = @_;
    my ($vol, $dir, $script) = File::Spec->splitpath($0);
    $appdir = Cwd::realpath(File::Spec->catdir($dir, File::Spec->updir));
    $class->run;
}

# overload run to read the global options before
# the App::Cmd object is created
sub run {
  my ($class) = @_;

  my ($global_opts, $argv) = $class->_process_args([@ARGV], $class->_global_option_processing_params);

  my $appdir = $global_opts->{appdir} || $ENV{DANCER_APPDIR} || $class->appdir;
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
