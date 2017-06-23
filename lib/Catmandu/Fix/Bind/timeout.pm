package Catmandu::Fix::Bind::timeout;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use Clone ();
use Time::HiRes;
use namespace::clean;

with 'Catmandu::Fix::Bind';

has time  => (is => 'ro');
has units => (is => 'ro', default => sub {'SECONDS'});
has sleep => (is => 'rw');

sub unit {
    my ($self, $data) = @_;

    my $sleep = $self->time;
    my $units = $self->units // 'SECONDS';

    if ($units =~ /^MICROSECOND(S)?$/i) {
        $sleep /= 1000000;
    }
    elsif ($units =~ /^MILLISECOND(S)$/i) {
        $sleep /= 1000;
    }
    elsif ($units =~ /^SECOND(S)?$/i) {

        # ok
    }
    elsif ($units =~ /^MINUTE(S)?$/i) {
        $sleep *= 60;
    }
    elsif ($units =~ /^HOUR(S)?$/i) {
        $sleep *= 3600;
    }
    else {
        # ok - use seconds
    }

    $self->sleep($sleep);

    [$data, Clone::clone($data)];
}

sub bind {
    my ($self, $mvar, $func) = @_;

    my $sleep = $self->sleep();

    if ($sleep >= 0) {
        my $start = [Time::HiRes::gettimeofday];

        $mvar->[0] = $func->($mvar->[0]);

        $sleep -= Time::HiRes::tv_interval($start);

        $self->sleep($sleep);
    }

    $mvar;
}

sub result {
    my ($self, $mvar) = @_;

    if ($self->sleep < 0) {
        $self->log->warn("timeout after > "
                . $self->time . " "
                . $self->units . " : "
                . (-1 * $self->sleep)
                . " extra time");
        inline_replace($mvar->[0], $mvar->[1]);
    }

    $self->sleep < 0 ? $mvar->[1] : $mvar->[0];
}

sub inline_replace {
    my ($old, $new) = @_;

    for my $key (keys %$old) {
        delete $old->{$key};
    }

    for my $key (keys %$new) {
        $old->{$key} = $new->{$key};
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Bind::timeout - run fixes that should run within a time limit

=head1 SYNOPSIS

    # The following bind will run fix1(), fix2(), ... fixN() only if the
    # action can be done in 5 seconds
    do timeout(time => 5, units => seconds)
       fix1()
       fix2()
       fix3()
       .
       .
       .
       fixN()
    end

    next_fix()

=head1 DESCRIPTION

The timeout binder will run the supplied block only when all the fixes can be
run within a time limit. All fixes (except side-effects) are ignored when the 
block can't be executed within the time limit. 

=head1 CONFIGURATION

=head2 timeout(time => VALUE , units => MICROSECOND|MILLISECONDS|SECONDS|MINUTES|HOURS)

Set a timeout to VALUE. This timeout doesn't prevent a fix script to run longer than the
specified value, but it does prevent fixes to have any effect when the timeout has been reached.

    # This script will run 10 seconds
    do timeout(time => 5, seconds)
       reject() # This will be ignored
       sleep(10,seconds)
       add_field(foo,bar) # This will be ignored
    end
    
At timeout a log message of level WARN will be generated.

=head1 SEE ALSO

L<Catmandu::Fix::Bind>

=cut
