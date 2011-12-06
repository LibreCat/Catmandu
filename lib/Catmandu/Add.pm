package Catmandu::Add;

use Catmandu::Sane;
use Catmandu::Util qw(is_invocant);
use Role::Tiny;

requires 'add';

sub add_many {
    my ($self, $next) = @_;
    if (is_invocant($next)) {
        $next = $next->generator;
    }
    my $n = 0;
    my $data;
    while ($data = $next->()) {
        $self->add($data);
        $n++;
    }
    $n;
}

1;
