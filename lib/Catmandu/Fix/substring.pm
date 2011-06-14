package Catmandu::Fix::substring;
use Catmandu::Sane;
use Catmandu::Util qw(value);
use Catmandu::Object;

sub _build_args {
    my ($self, $path, $key, $offset, $length) = @_;
    { path   => $path,
      key    => $key,
      offset => $offset,
      length => $length, };
}

sub fix {
    my ($self, $obj) = @_;

    my $key = $self->{key};
    my $offset = $self->{offset};
    my $length = $self->{length};
    my @values = $self->{path}->values($obj);

    for my $o (@values) {
        next if ref $o ne 'HASH';

        my $val = $o->{$key};

        if (ref $val eq 'ARRAY') {
            $o->{$key} = [ map { value($_) ? substr($_, $offset, $length) : $_ } @$val ];
        } elsif (value $val) {
            $o->{$key} = substr($val, $offset, $length);
        }
    }

    $obj;
}

1;
