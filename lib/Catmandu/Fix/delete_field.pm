package Catmandu::Fix::delete_field;
use Catmandu::Class;

sub build_args {
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
}

1;
