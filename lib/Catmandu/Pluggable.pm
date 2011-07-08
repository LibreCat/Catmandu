package Catmandu::Pluggable;
use Catmandu::Sane;
use Catmandu::Object;

sub _build {
    my ($self, $args) = @_;
    my $plugins = delete($args->{plugins}) || [];
    $self->{plugins} = [ map { load_package($_, 'Catmandu::Plugin')->new($self) } @$plugins ];
    $self->SUPER::_build($args);
}

sub plugins {
    if (wantarray) {
        return @{$_[0]->{plugins}};
    }
    $_[0]->{plugins};
}

1;
