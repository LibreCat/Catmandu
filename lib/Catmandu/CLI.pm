package Catmandu::CLI;
use Catmandu::Sane;
use Catmandu;
use App::Cmd::Setup -app;

sub global_opt_spec {
    (
        [ 'home|H=s', "the application's home directory" ],
        [ 'env|E=s', "the application's environment" ],
    );
}

# we overload run to read the global options before
# the App::Cmd object is created, giving us a chance to setup @INC etc.
sub run {
  my ($class) = @_;

  my ($global_opts, $argv) = $class->_process_args(\@ARGV, $class->_global_option_processing_params);

  Catmandu->init(home => $global_opts->{home}, env => $global_opts->{env});
  Catmandu->load_libs;
  Catmandu->auto;

  my $self = $class->new;

  $self->set_global_options($global_opts);

  my ($cmd, $opts, @args) = $self->prepare_command(@$argv);

  $self->execute_command($cmd, $opts, @args);
}

1;
