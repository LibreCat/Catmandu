package Catmandu::Fix::upcase;
use Catmandu::Util qw(is_value);
use Catmandu::Class;

sub build_args {
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
            $o->{$key} = [ map { is_value($_) ? uc($_) : $_ } @$val ];
        } elsif (is_value $val) {
            $o->{$key} = uc $val;
        }
    }
}

1;
