package Catmandu::Fix::join;
use Catmandu::Sane;
use Catmandu::Util qw(value);
use Catmandu::Object;

sub _build_args {
    my ($self, $path, $key, $str) = @_;
    { path => $path,
      key  => $key,
      str  => $str || ' ', };
}

sub fix {
    my ($self, $obj) = @_;

    my $key = $self->{key};
    my $str = $self->{str};
    my @values = $self->{path}->values($obj);

    FIX: for my $o (@values) {
        next if ref $o ne 'HASH';

        my $val = $o->{$key};

        if (ref $val eq 'ARRAY') {
            value($_) || next FIX for @$val;
            $o->{$key} = join $str, @$val;
        } elsif (ref $val eq 'HASH') {
            my @vals = values %$val;
            value($_) || next FIX for @vals;
            $o->{$key} = join $str, @vals;
        }
    }

    $obj;
}

1;
