package Catmandu::Fix::add_field;
use Catmandu::Class;

sub build_args {
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
}

1;
