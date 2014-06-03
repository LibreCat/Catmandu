package Catmandu::Logger;

use namespace::clean;
use Catmandu::Sane;
use Moo::Role;
use Log::Any ();

local $| = 1;

has 'log' => (is => 'lazy');

sub _build_log {
    my ($self) = @_;
    Log::Any->get_logger(category => ref($self));
}

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

with log4perl.conf as:

    log4perl.rootLogger=DEBUG,STDOUT
    log4perl.appender.STDOUT=Log::Log4perl::Appender::Screen
    log4perl.appender.STDOUT.stderr=1
    log4perl.appender.STDOUT.utf8=1

    log4perl.appender.STDOUT.layout=PatternLayout
    log4perl.appender.STDOUT.layout.ConversionPattern=%d [%P] - %p %l time=%r : %m%n

=head1 ACCESSORS

=head2 log

The C<log> attribute holds the L<Log::Any::Adapter> object that implements all logging methods for the
defined log levels, such as C<debug> or C<error>.

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

=head1 SEE ALSO

L<Log::Any>

=head1 ACKNOWLEDGMENTS

Code and documentation blatantly stolen from C<MooX::Log::Any>.

=cut

1;
