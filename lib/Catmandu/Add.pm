package Catmandu::Add;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Role::Tiny;

requires 'add';

sub add_many {
    my ($self, $many) = @_;

    my $data;

    if (is_array_ref($many)) {
        for $data (@$many) {
            $self->add($data);
        }
        return scalar(@$many);
    }

    $many = $many->generator if is_invocant($many);

    my $n = 0;
    while ($data = $many->()) {
        $self->add($data);
        $n++;
    }
    $n;
}

1;
