package Catmandu::Plugin::Store::Timestamps;
use Catmandu::Sane;
use parent qw(Catmandu::Plugin::Store);
use DateTime;

sub before_add {
    my ($self, $store, $obj) = @_;
    $obj->{updated_at} = DateTime->now->iso8601.'Z';
    $obj->{created_at} ||= $obj->{updated_at};
}

1;
