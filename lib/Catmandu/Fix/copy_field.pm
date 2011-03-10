package Catmandu::Fix::copy_field;
use Catmandu::Class;

sub build_args {
    my ($self, $path, $old, $new) = @_;
    { path => $path,
      old  => $old,
      new  => $new, };
}

sub fix {
    my ($self, $obj) = @_;

    my $old = $self->{old};
    my $new = $self->{new};
    my @values = $self->{path}->values($obj);

    for my $o (@values) {
        next if ref $o ne 'HASH';
        if (exists $o->{$old}) {
            $o->{$new} = $o->{$old};
        }
    }
}

1;
