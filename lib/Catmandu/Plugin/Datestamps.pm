package Catmandu::Plugin::Datestamps;

use Catmandu::Sane;
use Role::Tiny;
use DateTime;

before add => sub {
    my ($self, $data) = @_;
    $data->{date_updated} = DateTime->now->iso8601.'Z';
    $data->{date_created} ||= $data->{date_updated};
};

1;
