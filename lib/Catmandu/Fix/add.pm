package Catmandu::Fix::add;
use Catmandu::Sane;
use Catmandu::Object;

sub _build_args {
    my ($self, $path, $key, $val) = @_;
    { path => $path,
      key  => $key,
      val  => $val, };
}

sub fix {
    my ($self, $obj) = @_;

    my $key = $self->{key};
    my $val = $self->{val};
    my @values = $self->{path}->values($obj);

    for my $o (@values) {
        next if ref $o ne 'HASH';
        $o->{$key} = $val;
    }

    $obj;
}

1;
