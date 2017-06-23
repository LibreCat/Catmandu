package Catmandu::Fix::log;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use Catmandu;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable', 'Catmandu::Logger';

has message => (fix_arg => 1);
has level   => (fix_opt => 1);

sub fix {
    my ($self, $data) = @_;
    my $id    = $data->{_id} // '<undef>';
    my $level = $self->level // 'INFO';

    if ($level
        =~ /^(trace|debug|info|notice|warn|error|critical|alert|emergency)$/i)
    {
        my $lvl = lc $level;
        $self->log->$lvl(sprintf "%s : %s\n", $id, $self->message);
    }

    $data;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::log - Log::Any logger as fix

=head1 SYNOPSIS

  log('test123')

  log('hello world' , level:WARN)

=head1 DESCRIPTION

This fix add debugging capabilities to fixes. To use it via the command line you need to add the
'-D' option to your script. E.g.

  echo '{}' | catmandu convert -D to YAML --fix 'log("help!", level:WARN)'

By default all logging messages have a level:INFO and will not be displayed unless
a log4perl configuration is in place (see below). Using log messages without a
log4perl configuration requires a log level of 'WARN', 'ERROR' or 'FATAL'.

=head1 CONFIGURATION

To have a full control over the log messages, create a 'catmandu.yml' with a
'log4perl' section as shown below:

    $ cat catmandu.yml
    log4perl: |
     log4perl.category.Catmandu::Fix::log=TRACE,OUT
     log4perl.appender.OUT=Log::Log4perl::Appender::Screen
     log4perl.appender.OUT.stderr=1
     log4perl.appender.OUT.utf8=1

     log4perl.appender.OUT.layout=PatternLayout
     log4perl.appender.OUT.layout.ConversionPattern=%d [%P] - %p %l time=%r : %m%n

Using this configuration file all logging messages are written to the screen
(stderr output). With this configuration in place use the L<catmandu> command
with the -D option to view the logging output:

    $ echo '{}' | catmandu convert -D to YAML --fix 'log("help!")' > output.yaml 2> log.txt

The Unix redirections '>' and '2>' can be used to write the output of the
catmandu command and the logging in two separate files.

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Logger> , L<Log::log4perl>

=cut
