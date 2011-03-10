package Catmandu::Fix::substring;
use Catmandu::Util qw(is_value);
use Catmandu::Class;

sub build_args {
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
            is_value($_) || next FIX for @$val;
            $o->{$key} = join $str, @$val;
        } elsif (ref $val eq 'HASH') {
            my @vals = values %$val;
            is_value($_) || next FIX for @vals;
            $o->{$key} = join $str, @vals;
        }
    }
}

1;
