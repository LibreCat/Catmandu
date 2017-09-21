package Catmandu::Logger;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Moo::Role;
use Log::Any ();
use namespace::clean;

has log => (is => 'lazy', init_arg => undef);
has log_category => (is => 'lazy');

{
    my $loggers = {};

    sub _build_log {
        my ($self) = @_;
        my $category = $self->log_category;
        $loggers->{$category} ||= Log::Any->get_logger(category => $category);
    }
}

sub _build_log_category {
    ref $_[0];
}

1;

__END__

=pod

=head1 NAME

Catmandu::Logger - A role for classes that need logging capabilities

=head1 SYNOPSIS

    package MyApp::View;
    use Moo;

    with 'Catmandu::Logger';

    sub something {
        my ($self) = @_;
        $self->log->debug("started bar"); # logs with default class catergory "MyApp::View"
        $self->log->error("started bar");
    }

=head1 DESCRIPTION

A logging role building a very lightweight wrapper to L<Log::Any>.  Connecting
a Log::Any::Adapter should be performed prior to logging the first log message,
otherwise nothing will happen, just like with Log::Any.

The logger needs to be setup before using the logger, which could happen in the main application:

    package main;
    use Log::Any::Adapter;
    use Log::Log4perl;

    Log::Any::Adapter->set('Log4perl');
    Log::Log4perl::init('./log4perl.conf');

    my $app = MyApp::View->new;
    $app->something();  # will print debug and error messages

with log4perl.conf like:

    log4perl.rootLogger=DEBUG,OUT
    log4perl.appender.OUT=Log::Log4perl::Appender::Screen
    log4perl.appender.OUT.stderr=1
    log4perl.appender.OUT.utf8=1

    log4perl.appender.OUT.layout=PatternLayout
    log4perl.appender.OUT.layout.ConversionPattern=%d [%P] - %p %l time=%r : %m%n

See L<Log::Log4perl> for more configuration options and selecting which messages
to log and which not.

=head1 CATMANDU COMMAND LINE

When using the L<catmandu> command line, the logger can be activated using the
-D option on all Catmandu commands:

     $ catmandu -D convert JSON to YAML < data.json
     $ catmandu -D export MongoDB --database-name items --bag

The log4perl configuration for the C<catmandu> command line must be defined in a
'catmandu.yml' configuration file:

     $ cat catmandu.yml
     log4perl: |
       log4perl.rootLogger=DEBUG,OUT
       log4perl.appender.OUT=Log::Log4perl::Appender::Screen
       log4perl.appender.OUT.stderr=1
       log4perl.appender.OUT.utf8=1

       log4perl.appender.OUT.layout=PatternLayout
       log4perl.appender.OUT.layout.ConversionPattern=%d [%P] - %p %l time=%r : %m%n

The C<log4perl> section can point to an inline log4perl configuration or a
filename containing the configuration.

See L<Catmandu::Fix::log> how to include log messages in the L<Catmandu::Fix>
language.

=head1 ACCESSORS

=head2 log

The C<log> attribute holds the L<Log::Any::Adapter> object that implements all
logging methods for the defined log levels, such as C<debug> or C<error>.

    package MyApp::View::JSON;

    extends 'MyApp::View';
    with 'Catmandu::Logger';

    sub bar {
        $self->log->info("Everything fine so far");   # logs a info message
        $self->log->debug("Something is fishy here"); # logs a debug message
    }

Your package automatically has a logging category of MyApp::View::JSON. Use lines like:

    log4perl.logger.MyApp::View::JSON=DEBUG,STDOUT

or

    log4perl.logger.MyApp::View=DEBUG,STDOUT

or

    log4perl.logger.MyApp=DEBUG,STDOUT

for specialized logging for your application.

=head2 log_category

Default is the class name.

=head1 SEE ALSO

L<Log::Any>

=cut
