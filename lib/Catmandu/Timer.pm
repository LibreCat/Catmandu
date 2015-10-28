package Catmandu::Timer;
use Time::HiRes qw(gettimeofday tv_interval);

sub new  {
    my $class = $_[0];
    bless {
        _t => [gettimeofday()],
        _te => [gettimeofday()],
        _n => 0
    },$class;
}
sub reset {
    my $self = $_[0];
    $self->{_t} = [gettimeofday()];
    $self->{_te} = [gettimeofday()];
    $self->{_n} = 0;
}
sub elapsed {
    tv_interval($_[0]->{_t});
}
sub elapsed_event {
    tv_interval($_[0]->{_te});
}
sub tick {
    $_[0]->{_n}++;
    $self->{_te} = [gettimeofday()];
}
sub benchmark {
    my $self = $_[0];
    $self->{_n},$self->{_n}/$self->elapsed();
}
sub benchmark_verbose {
    my($self,%opts)=@_;

    $opts{template} //= "processed %9d (%d/sec)\n";
    $opts{repeat} //= 100;
    $opts{fh} //= \*STDERR;
    my $fh = $opts{fh};

    my($nn,$avg) = $self->benchmark();

    if($nn % $opts{repeat} == 0){
        printf $fh $opts{template},$nn,$avg;
    }
}

=head1 NAME

Catmandu::Timer - package for timing of events

=head1 DESCRIPTION

This package implements a stopwatch. Once created,
you can register 'events' by calling the method 'tick'.
It counts the number and the global elapsed time
of all events.

You can also get benchmarking information.

=head1 SYNOPSIS

    #create a timer object
    my $timer = Catmandu::Timer->new();
    for(1..10000){
        #start event
        ...

        #get elapsed time for the event
        say $timer->elapsed_event();

        #register end of the event:
        #   the timer for the current event is reset to zero
        #   but the global timer keeps on ticking
        $timer->tick();
    }
    #get average time per event
    my($num_events,$avg_per_event) = $timer->benchmark();

    #reset timer
    $timer->reset();

    for(1..10000){
        #start event
        ...
        #get global elapsed time in seconds
        my $elapsed = $timer->elapsed();
    }

=head1  FUNCTIONS

=over 4

=item reset

reset global start time to the current time, and set the event counter to 0.

=item elapsed

get difference in seconds between (global) start time and the current time

=item elapsed_event

get difference in seconds between start time of an event, and the current time.

=item tick

register end of an event. This is used to calculate the average time per second for all events.

=item benchmark

get benchmark information, i.e. the number of events and the average time per event.

=item benchmark_verbose(template => <template>,repeat => <repeat>,fh => <fh>)

print benchmark information to a file handle.

template    template string. First argument is the number of events, the second the average time per second.
            default: "processed %9d (%d/sec)\n"

repeat      print only after <repeat> number of times.
            default: 100

fh          file handle
            default: STDERR


=back

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=cut

1;
