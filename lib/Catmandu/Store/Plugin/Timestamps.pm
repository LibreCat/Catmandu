package Catmandu::Store::Plugin::Timestamps;
use Catmandu::Sane;
use DateTime;

sub import_plugin {
    my ($plugin, $store, $opts) = @_;

    $store->before(save => sub {
        my $obj = $_[1];
        $obj->{_updated_at} = DateTime->now->iso8601.'Z';
        $obj->{_created_at} ||= $obj->{_updated_at};
    });
}

1;
