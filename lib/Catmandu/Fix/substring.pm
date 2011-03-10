package Catmandu::Fix::substring;
use Catmandu::Util qw(is_value);
use Catmandu::Class;

sub build_args {
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
            $o->{$key} = [ map { is_value($_) ? substr($_, $offset, $length) : $_ } @$val ];
        } elsif (is_value $val) {
            $o->{$key} = substr($val, $offset, $length);
        }
    }
}

1;
