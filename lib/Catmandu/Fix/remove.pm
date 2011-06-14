package Catmandu::Fix::remove;
use Catmandu::Sane;
use Catmandu::Object;

sub _build_args {
    my ($self, $path, @keys) = @_;
    { path => $path,
      keys => [ @keys ], };
}

sub fix {
    my ($self, $obj) = @_;

    my $keys = $self->{keys};
    my @values = $self->{path}->values($obj);

    for my $o (@values) {
        next if ref $o ne 'HASH';
        for my $k (@$keys) {
            delete $o->{$k};
        }
    }

    $obj;
}

1;
