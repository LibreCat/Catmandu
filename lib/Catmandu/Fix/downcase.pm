package Catmandu::Fix::downcase;
use Catmandu::Sane;
use Catmandu::Util qw(value);
use Catmandu::Object;

sub _build_args {
    my ($self, $path, $key) = @_;
    { path => $path,
      key  => $key, };
}

sub fix {
    my ($self, $obj) = @_;

    my $key = $self->{key};
    my @values = $self->{path}->values($obj);

    for my $o (@values) {
        next if ref $o ne 'HASH';

        my $val = $o->{$key};

        if (ref $val eq 'ARRAY') {
            $o->{$key} = [ map { value($_) ? lc($_) : $_ } @$val ];
        } elsif (value $val) {
            $o->{$key} = lc $val;
        }
    }

    $obj;
}

1;
