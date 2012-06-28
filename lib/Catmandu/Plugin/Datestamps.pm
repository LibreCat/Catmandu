package Catmandu::Plugin::Datestamps;

use Catmandu::Sane;
use Role::Tiny;
use POSIX qw(strftime);

before add => sub {
    my ($self, $data) = @_;
    my $now = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time));
    $data->{date_created} ||= $now;
    $data->{date_updated} = $now;
};

no POSIX;

1;
