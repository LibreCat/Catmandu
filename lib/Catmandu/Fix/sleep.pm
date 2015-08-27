package Catmandu::Fix::sleep;

use Catmandu::Sane;
use Moo;
use Time::HiRes;
use Catmandu::Fix::Has;

has seconds => (fix_arg => 1);
has units   => (fix_arg => 1);

sub fix {
    my ($self, $data) = @_;

    my $sleep = $self->seconds;
    my $units = $self->units;

    if ($units =~ /^MICROSECOND(S)?$/i) {}
    elsif ($units =~ /^MILLISECOND(S)$/i) {
      $sleep *= 1000;
    }
    elsif ($units =~ /^SECOND(S)?$/i) {
      $sleep *= 1000000;
    }
    elsif ($units =~ /^MINUTE(S)?$/i) {
      $sleep *= 60*1000000;
    }
    elsif ($units =~ /^HOUR(S)?$/i) {
      $sleep *= 3600 * 1000000;
    }
    else {
      $sleep *= 1000000;
    }

    Time::HiRes::usleep($sleep);

    $data;
}

=head1 NAME

Catmandu::Fix::sleep - Do nothing for a specified ammount of time

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

1;