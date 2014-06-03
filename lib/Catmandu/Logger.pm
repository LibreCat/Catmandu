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

    package MyApp;
    use Moo;

    with 'Catmandu::Logger';

    sub something {
        my ($self) = @_;
        $self->log->debug("started bar"); # logs with default class catergory "MyApp"
        $self->log->error("started bar");
    }

=head1 DESCRIPTION

A logging role building a very lightweight wrapper to L<Log::Any>.  Connecting
a Log::Any::Adapter should be performed prior to logging the first log message,
otherwise nothing will happen, just like with Log::Any.

The logger needs to be setup before using the logger, which could happen in the main application:

    package main;
    use Log::Any::Adapter;
    # Send all logs to Log::Log4perl
    Log::Any::Adapter->set('Log4perl')


=head1 ACCESSORS

=head2 log

The C<log> attribute holds the L<Log::Any::Adapter> object that implements all logging methods for the
defined log levels, such as C<debug> or C<error>. As this method is defined also in other logging
roles/systems like L<MooseX::Log::LogDispatch> this can be thought of as a common logging interface.

    package MyApp::View::JSON;

    extends 'MyApp::View';
    with 'MooseX:Log::Log4perl';

    sub bar {
        $self->logger->info("Everything fine so far");   # logs a info message
        $self->logger->debug("Something is fishy here"); # logs a debug message
    }

=head1 SEE ALSO

L<Log::Any>

=head1 ACKNOWLEDGMENTS

Code and documentation blatantly stolen from C<MooX::Log::Any>.

=cut

1;
