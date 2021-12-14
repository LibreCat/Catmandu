package Catmandu::Fix::sleep;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use Time::HiRes;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

has seconds => (fix_arg => 1);
has units   => (fix_arg => 1);

sub fix {
    my ($self, $data) = @_;

    my $sleep = $self->seconds;
    my $units = $self->units;

    if    ($units =~ /^microsecond(s)?$/i) { }
    elsif ($units =~ /^millisecond(s)$/i) {
        $sleep *= 1000;
    }
    elsif ($units =~ /^second(s)?$/i) {
        $sleep *= 1000000;
    }
    elsif ($units =~ /^minute(s)?$/i) {
        $sleep *= 60 * 1000000;
    }
    elsif ($units =~ /^hour(s)?$/i) {
        $sleep *= 3600 * 1000000;
    }
    else {
        $sleep *= 1000000;
    }

    Time::HiRes::usleep($sleep);

    $data;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::sleep - Do nothing for a specified amount of time

=head1 SYNOPSIS
  
    sleep(10,MICROSECONDS)

    sleep(3,MILLISECONDS)

    sleep(1,SECOND)
    sleep(2,SECONDS)

    sleep(5,MINUTES)

    sleep(1,HOURS)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
