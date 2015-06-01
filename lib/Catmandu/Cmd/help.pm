package Catmandu::Cmd::help;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use App::Cmd::Command::help;
use Catmandu::Util qw(require_package pod_section);

sub description { 'show help' }

sub usage_desc { '%c help [ command | exporter X | importer Y ]' }

sub command_names { qw/help --help -h -?/ }


sub execute {
  my ($self, $opts, $args) = @_;

  if ( @$args == 2 ) {
    # detect many forms such as:
    # export JSON, exporter JSON, JSON export, JSON exporter
    foreach my $type (qw(export import)) {
      foreach my $index (0,1) {
        if ( $args->[$index] =~ /^$type(er)?$/i ) {
          $self->help_about($type, $args->[ ($index+1) % 2]);
          return;
        }
      }
    }
  } 
  
  App::Cmd::Command::help::execute(@_);
}

sub help_about {
  my ($self, $type, $name) = @_;

  my $class = "Catmandu::".ucfirst($type)."er::$name";
  require_package($class);

  # Show importer/exporter options
  my $pod = pod_section($class,"configuration");

  $pod =~ s/^([a-z0-9_-]+)\s*\n/--$1, /mgi;
  $pod =~ s/^(--.*),(\s*[^-])/ $1\n$2/mgi;

  my $about = pod_section($class,"name");

  if ($type eq 'export') {
    say "catmandu convert ... to $name [options]\n";
  } else { 
    say "catmandu convert $name [options] ...\n";
  }
  print "$about";
  print "\n$pod" if $pod;
}

1;
__END__

=head1 NAME

Catmandu::Cmd::help - show help

=cut 
