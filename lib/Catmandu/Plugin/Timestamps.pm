package Catmandu::Plugin::Timestamps;
use Catmandu::Sane;
use DateTime;

sub after_get {}
sub before_add {}
sub after_add {}
sub before_delete {}

sub before_add {
    my ($self, $store, $obj) = @_;
    $obj->{updated_at} = DateTime->now->iso8601.'Z';
    $obj->{created_at} ||= $obj->{updated_at};
}

1;
